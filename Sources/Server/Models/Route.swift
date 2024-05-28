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

	func measureTotalDistanceAlongRoute() -> Double {
		var distanceAlongRoute: Double = 0
		for index in self.coordinates.startIndex ..< self.coordinates.endIndex-1 {
			distanceAlongRoute += self.coordinates[index].distance(to: self.coordinates[index+1])
		}
		return distanceAlongRoute
	}

	// Finds the closest vertex's rtept and the index from self.coordinates
	// Parameter: The bus location
	public func findClosestVertex(location: Coordinate) -> (LocationCoordinate2D, Int) {
		var maxDistance: Double = Double.infinity
		var closestVertex: LocationCoordinate2D = self.coordinates[0]
		var closestIndex: Int = 0

		// find vertex with smallest distance to the current bus location
		for index in self.coordinates.startIndex ..< (self.coordinates.endIndex) {
			let distance = self.coordinates[index].distance(to: location)
			if distance < maxDistance {
					closestVertex = self.coordinates[index]
					closestIndex = index
					maxDistance = distance
			}
		}
		return (closestVertex,closestIndex)
	}

	// Returns the size of self.coordinatess
	public func getSize() -> Int {
		return self.coordinates.count
	}

	// Returns the linear distances between two rtepts
	public func getDistanceBetweenRtept(beginIndex: Int, endIndex: Int) -> Double {
		var distance: Double = 0.0
		for index in beginIndex ..< endIndex {
			distance += self.coordinates[index].distance(to:self.coordinates[index+1])
		}
		return distance
	}


	/// Get the total distance traveled along route
	/// - Parameter location: The location to check
	/// - Optional parameter distanceAlongRoute: the total distance the shuttle has traveled thus far
	/// - Returns: The total distance between the bus location
	public func getTotalDistanceTraveled(location: Coordinate, previousCoordinate: Coordinate) -> Double {
		/*
			Things to consider/note:
				1) If the shuttle is at the union, the route can be either North or West
					- Both location and previousCoordinate is within the same route
		*/
		var totalDistance: Double = 0

		// Get the closest vertex in the form of rtept and index
		let closestVertex: (LocationCoordinate2D, Int) = findClosestVertex(location: location)
		let previousClosestVertex: (LocationCoordinate2D, Int) = findClosestVertex(location: previousCoordinate)

		let directionIsReversed: Bool = closestVertex.1 < previousClosestVertex.1
		
		// Flag to determine if we have reached the point where we want to start 
		// tracking previous location to location
		var reachedClosestVertex: Bool = false

		var locationToCheck:(LocationCoordinate2D, Int) = closestVertex
		
		if (!directionIsReversed){
			locationToCheck = previousClosestVertex
		}


		// get the total distance that have been traveled
		for index in 0 ..< (self.coordinates.endIndex-1) {
			// since the direction is not reverse, we can just continue up until previousLocation
			// near the first rtept, proceed with the algorithm
			if (index == closestVertex.1) {
				return self.coordinates[0].distance(to: location)
			}

			else if(index+1 != locationToCheck.1) {
				// skip till we get the location we are checking first
				if (reachedClosestVertex) {
					totalDistance += self.coordinates[index].distance(to: self.coordinates[index+1])
				}
				continue;
			}		
			if (directionIsReversed) {
				// ALGORITHM
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
				let vertexX: Coordinate = locationToCheck.0

				// distances between the vertices
				let distanceAB: Double = vertexA.distance(to: vertexB)
				let distanceBC: Double = vertexB.distance(to: vertexC)
				let distanceAX: Double = vertexA.distance(to: vertexX)
				let distanceBX: Double = vertexB.distance(to: vertexX)
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
				// we set the necessary flags to begin tracking 
				locationToCheck = closestVertex
				reachedClosestVertex = true
			}
			else {
				let distanceAB = self.coordinates[index-1].distance(to: self.coordinates[index])
				let distanceBC = self.coordinates[index].distance(to: self.coordinates[index+1])
				if (index > closestVertex.1) {
					totalDistance += distanceAB
				}
				else {
					totalDistance += distanceBC
				}
			}
		}
		// print(totalDistance)
		return totalDistance
	}
}
