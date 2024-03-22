//
//  Route.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 10/9/20.
//

import CoreGPX
import FluentKit
import JSONParser
import Turf
import Vapor

/// A representation of a shuttle route.
///
/// A route is represented as a sequence of geospatial coordinates.
final class Route: Model, Content, Collection {
	
	static let schema = "routes"
	
	let startIndex = 0
	
	var endIndex: Int {
		get {
			return self.coordinates.count
		}
	}
	
	@ID
	var id: UUID?
	
	/// The user-facing display name of this route.
	@Field(key: "name")
	var name: String
	
	/// The waypoint coordinates that define this route.
	@Field(key: "coordinates")
	var coordinates: [Coordinate]
	
	/// A schedule that determines when this route is active.
	@Field(key: "schedule")
	var schedule: MapSchedule
	
	/// The name of the color that clients should use to draw the route.
	@Field(key: "color_name")
	var colorName: ColorName

	// The total distance along the route
	@Field(key: "distance_along_route")
	var distanceAlongRoute: Double
	
	init() { }
	
	/// Creates a route object from a GPX route with a custom schedule.
	/// - Parameters:
	///   - gpxRoute: The GPX route from which to create a route object.
	///   - schedule: The schedule for when the route will be active.
	convenience init(from gpxRoute: GPXRoute, schedule: MapSchedule) {
		var colorName: ColorName?
		if let rawColorName = gpxRoute.comment?.lowercased() {
			colorName = ColorName(rawValue: rawColorName)
		}
		self.init(
			name: gpxRoute.name ?? "Route",
			from: gpxRoute,
			schedule: schedule,
			colorName: colorName ?? .gray
		)
	}
	
	/// Creates a route object from a GPX route with a custom name, schedule, and color name.
	/// - Parameters:
	///   - name: The user-facing display name of the route.
	///   - gpxRoute: The GPX route from which to create a route object.
	///   - schedule: The schedule for when the route will be active.
	///   - colorName: The name of the color that clients should use to draw the route.
	convenience init(name: String, from gpxRoute: GPXRoute, schedule: MapSchedule, colorName: ColorName) {
		let coordinates = gpxRoute.points.compactMap { (gpxRoutePoint) in
			return Coordinate(from: gpxRoutePoint)
		}
		self.init(
			name: name,
			coordinates: coordinates,
			schedule: schedule,
			colorName: colorName
		)
	}
	
	/// Creates a route object from a GPX track segment with a custom name, schedule, and color name.
	/// - Parameters:
	///   - name: The user-facing display name of the route.
	///   - gpxTrackSegment: The GPX track segment from which to create a route object.
	///   - schedule: The schedule for when the route will be active.
	///   - colorName: The name of the color that clients should use to draw the route.
	convenience init(name: String, from gpxTrackSegment: GPXTrackSegment, schedule: MapSchedule, colorName: ColorName) {
		let coordinates = gpxTrackSegment.points.compactMap { (gpxTrackPoint) in
			return Coordinate(from: gpxTrackPoint)
		}
		self.init(
			name: name,
			coordinates: coordinates,
			schedule: schedule,
			colorName: colorName
		)
	}
	
	/// Creates a route object from an array of coordinates with a custom name, schedule, and color name.
	/// - Parameters:
	///   - name: The user-facing display name of the route.
	///   - coordinates: The array of coordinates from which to create a route object.
	///   - schedule: The schedule for when the route will be active.
	///   - colorName: The name of the color that clients should use to draw the route.
	///   - distanceAlongRoute: The total distance along the route
	init(name: String, coordinates: [Coordinate], schedule: MapSchedule, colorName: ColorName) {
		self.name = name
		self.coordinates = coordinates
		self.schedule = schedule
		self.colorName = colorName
		self.distanceAlongRoute = measureTotalDistanceAlongRoute()
	}
	
	/// Gets the coordinate at the specified index.
	subscript(_ index: Int) -> Coordinate {
		return self.coordinates[index]
	}
	
	func index(after oldIndex: Int) -> Int {
		return oldIndex + 1
	}
	
	/// Checks if the specified location is on this route.
	/// - Parameter location: The location to check.
	/// - Returns: `true` if the specified location is on this route; otherwise, `false`.
	func checkIsOnRoute(location: Bus.Location) -> Bool {
		let distance = LineString(self.coordinates)
			.closestCoordinate(to: location.coordinate)?
			.coordinate
			.distance(to: location.coordinate)
		guard let distance else {
			return false
		}
		return distance < Constants.isOnRouteThreshold
	}


	func checkIsNearby(location: Coordinate) -> Bool { 
		let distance = LineString(self.coordinates)
			.closestCoordinate(to: location)?
			.coordinate
			.distance(to: location)
		guard let distance else {
			return false
		}
		return distance < Constants.isNearRouteCoordinateThreshold
	}

	// returns true if and only if the shuttle just started at the union and is moving away from it
	// returns false if it is entering union after its trip at the route
	// distanceAlongRoute is the distance the shuttle has already traveled
	// returns the nearest vertex at the union 
	func checkIsAtUnion(location: Coordinate, distanceAlongRoute: Double) -> (Bool,Coordinate) { 
		// West route has the union coordinates as the last 7 rtepts
		if (name == "West Route") {
			for points in self.coordinates.endIndex-7 ... self.coordinates.endIndex-1 {
				let distance = self.coordinates[points].distance(to: location)
				if (distance < 10) {
					if (distanceAlongRoute < 200) {
						return (true,self.coordinates[points])
					}
					else {
						return (false,self.coordinates[points])
					}
				}
			}
		}
		return (false, self.coordinates[self.coordinates.endIndex-1])
	}

	// Calculates the total distance along the route
	func measureTotalDistanceAlongRoute() -> Double {
		var distanceAlongRoute: Double = 0
		for index in self.coordinates.startIndex ..< self.coordinates.endIndex-1 {
			distanceAlongRoute += self.coordinates[index].distance(to: self.coordinates[index+1])
		}
		return distanceAlongRoute
	}

	// Find closest vertex 
	// Parameter: The bus location
	public func findClosestVertex(location: Coordinate) -> LocationCoordinate2D? {
		var maxDistance: Double = Double.infinity
		var closestVertex: LocationCoordinate2D? = self.coordinates[0]

		// find vertex with smallest distance to the current bus location
		for index in self.coordinates.startIndex ..< (self.coordinates.endIndex - 1) {
			let distance = self.coordinates[index].distance(to: location)
			if distance < maxDistance {
					closestVertex = self.coordinates[index]
					maxDistance = distance
			}
		}
		return closestVertex
	}

	// determines whether or not the bus is moving away or towards the union
	// returns true if moving towards the uniom, false otherwise/unknown
	func detectUnionDirection(location: Coordinate, previousLocation: Coordinate) -> Bool {
		// unknown
		if (location == previousLocation) {
			return false
		}
		
		var firstIndex: Int = 0 // represents the rtept index of location
		var secondIndex: Int = 0 //represents the rtept index of previousLocation
		// not close to the union
		if (checkIsAtUnion(location: location).0) {
			for index in self.coordinates.startIndex ..< (self.coordinates.endIndex-7) {
				if (self.coordinates[index] == location) {
					firstIndex = index
				}
				else if (self.coordinates[index] == previousLocation) {
					secondIndex = index
				}
			}
			if (firstIndex > secondIndex) {
				return true
			}
		}
		return false
	}

	// calculates the distance around the union
	// used only when the shuttle has left the union and is now on the move
	func getUnionDistance() -> Double {
		var totalDistance: Double = 0
		for points in self.coordinates.endIndex-7 ... self.coordinates.endIndex-1 {
			totalDistance += self.coordinates[points].distance(to: self.coordinates[points+1])
		}
		return totalDistance
	}

	/// Get the total distance traveled along route
	/// - Parameter location: The location to check
	/// - Optional parameter distanceAlongRoute: the total distance the shuttle has traveled thus far
	/// - Returns: The total distance between the bus location
	public func getTotalDistanceTraveled(location: Coordinate, distanceAlongRoute: Double = 0) -> Double {
		// We can safely assume that we are not starting at the unioin if totalDistance is greater than 200
		// If distanceAlongRoute is greater than 200, 
		// we can assume that it is coming back to the union rather than exiting from the union
		var totalDistance: Double = distanceAlongRoute

		// determines whether or not the shuttle just started out of union and just began to move
		let atUnion: Bool = checkIsAtUnion(location: location, distanceAlongRoute: distanceAlongRoute).0
		let nearestAtUnionVertex: Coordinate = checkIsAtUnion(location: location, distanceAlongRoute: distanceAlongRoute).1

		if (totalDistance == 0 && !atUnion) {
			totalDistance = getUnionDistance()
		}

		var beginningIndex: Int = 0

		let closestVertex: LocationCoordinate2D = findClosestVertex(location: location)!
	

		// Begins on the road and not on the horseshoe at the Union
		// North Route
		if (self.name == "North Route") {
			beginningIndex = 7
		}

		// get the total distance that have been traveled
		for index in beginningIndex ..< (self.coordinates.endIndex-1) {
			// near the first rtept, proceed with the algorithm
			if (
					self.coordinates[0].longitude == closestVertex.longitude &&
					self.coordinates[0].latitude == closestVertex.latitude) {
						return self.coordinates[0].distance(to: location)
			}

			else if(self.coordinates[index+1].longitude != closestVertex.longitude &&
					self.coordinates[index+1].latitude != closestVertex.latitude) {
				totalDistance += self.coordinates[index].distance(to: self.coordinates[index+1])
				continue;
			}			 

			/*
				3 edge Cases:
				1) 
					|--x1--|--x2--| 
					a      b      c

				2) 
					|--x1--|--x2-------| 
					a      b           c

				3) 
					|-------x1--|--x2--| 
					a           b      c
			 	VertexA = vertex behind the closest vertex
				VertexB = the closest vertex
			 	vertexC = vertex in front of the closest vertex
			 	Determine the edge cases based off the distance of the current
			 	location to the surrounding vertex
			*/


			// behind/front/on closest vertex
			let vertexA: Coordinate = self.coordinates[index]
			let vertexB: Coordinate = self.coordinates[index+1]
			let vertexC: Coordinate = self.coordinates[index+2]
			let vertexX: Coordinate = location

			// distances between the vertices
			let distanceAB: Double = vertexA.distance(to: vertexB)
			let distanceBC: Double = vertexB.distance(to: vertexC)
			let distanceAX: Double = vertexA.distance(to: vertexX)
			let distanceBX: Double = vertexB.distance(to:vertexX)
			let distanceXC: Double = vertexX.distance(to: vertexC)
			let distanceCX: Double = vertexC.distance(to: vertexX)

			
			// first  test case
			if (distanceAB == distanceBC) {
				if (distanceAX < distanceXC) {
					totalDistance += distanceAX
				}
				else {
					totalDistance += distanceXC
				}

			}
			
			// distance difference depending on location of bus
			var delta1: Double = distanceBC - distanceAX
			var delta2: Double = distanceBC - distanceAB
			
			// second test case
			if (distanceAB < distanceBC) {
				if (delta1 < delta2) {
					totalDistance += distanceBX
				}
				else {
					totalDistance += distanceAX
				}
			}
			
			delta1 = distanceAB - distanceCX
			delta2 = distanceAB - distanceBC

			// third test case
			if (distanceAB > distanceBC)  {
				if (delta1 < delta2) {
					totalDistance += distanceAX
				}
				else {
					totalDistance += distanceBX
				}
			}
			break
		}
		return totalDistance
	}
}
