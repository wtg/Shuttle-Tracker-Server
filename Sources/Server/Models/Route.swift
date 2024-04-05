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

	// Finds the closest vertex's index
	// Parameter: The bus location
	public func findClosestVertex(location: Coordinate) -> Int {
		var maxDistance: Double = Double.infinity
		var closestVertex: Int = 0

		// find vertex with smallest distance to the current bus location
		for index in self.coordinates.startIndex ..< (self.coordinates.endIndex) {
			let distance = self.coordinates[index].distance(to: location)
			if distance < maxDistance {
					closestVertex = index
					maxDistance = distance
			}
		}
		return closestVertex
	}

	/// Get the total distance traveled along route
	/// - Parameter location, previousLocation: the current shuttle location and the previous shuttle location
	/// - Returns: The total distance between the union(moving away) and the bus location
	public func getTotalDistanceTraveled(location: Coordinate, previousCoordinate: Coordinate) -> Double {
		// we want to get the union rtepts to the beginning and have union rtepts at the end
		var totalDistance: Double = 0

		var coordinates = self.coordinates

		if (name == "West Route") {
			let firstIndex = self.coordinates.endIndex-7
			let endIndex = self.coordinates.endIndex
			let unionRtept = self.coordinates[firstIndex ..< endIndex]
			let restCoordinates = self.coordinates[0 ..< firstIndex]
			coordinates = Array( unionRtept + restCoordinates + unionRtept)
		}
		

		let closestVertex: Int = findClosestVertex(location: location)
		// will be set to -1 if there does not exist a previousCoordinate
		var previousClosestVertex: Int? = -1
		if (previousCoordinate != nil) {
			previousClosestVertex = findClosestVertex(location: previousCoordinate!)
		}

		// location rtept == previous location rtept
		// something went wrong
		if (previousClosestVertex != nil && closestVertex == previousClosestVertex) {
			return 0
		}

		for index in self.coordinates.startIndex ..< self.coordinates.endIndex {
			// we have reached the closest vertex (of current location)
			if (rtept == closestVertex) {
				// first rtept of the route (not the union) is nearby
				// |--x1--|--x2--|
				// ?      a      b
				// current location is at ? whereas the first rtept of self.coordinates is a
				if (index == 0) {
					return self.coordinates[index].distance(to: location)
				}
				else {
					// the accurate distance from previousLocation to location
					var distance = 0	
					var busIsBeforeClosestVertex = true
					/*
					Moving away from the union, i.e. is not traveling back to the union
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
					let distanceBX: Double = vertexB.distance(to: vertexX)
					let distanceXC: Double = vertexX.distance(to: vertexC)
					let distanceCX: Double = vertexC.distance(to: vertexX)

					// distance difference depending on location of bus
					var delta1: Double = distanceBC - distanceAX
					var delta2: Double = distanceBC - distanceAB
					
					// first  test case
					if (distanceAB == distanceBC) {
						if (distanceAX < distanceXC) {
							distance = distanceAX
							busIsBeforeClosestVertex = false
						}
						else {
							distance = distanceXC
						}
					}
					
					// second test case
					else if (distanceAB < distanceBC) {
						if (delta1 < delta2) {
							distance = distanceBX
							busIsBeforeClosestVertex = false
						}
						else {
							distance = distanceAX
						}
					}
					
					// third test case
					else if (distanceAB > distanceBC)  {
						delta1 = distanceAB - distanceCX
						delta2 = distanceAB - distanceBC
						if (delta1 < delta2) {
							distance = distanceAX
							busIsBeforeClosestVertex = false
						}
						else {
							distance = distanceBX
						}
					}
					/*
						Moving towards the union, i.e. traveling back to the union
						|------x1--|--x2------| 
						a          b          c
						<----------------------  (direction)
					*/
					var distBetweenTwoVertex = 0.0
					var distBetweenVertexToCurrent = 0.0
					if (closestVertex < previousClosestVertex) {
						let distanceAB = self.coordinates[index-1].distance(to: self.coordinates[index])
						let distanceBC = self.coordinates[index].distance(to: self.coordinates[index+1])
						// case 1: shuttle is behind the nearest rtept, i.e. at x1
						if (busIsBeforeClosestVertex) {
							distBetweenTwoVertex = distanceAB
							distBetweenVertexToCurrent = distBetweenTwoVertex - distance
						}
						// case 2: shuttle is ahead of the nearest rtept, i.e. at x2
						else {
							distBetweenTwoVertex = distanceBC
							distBetweenVertexToCurrent = distBetweenTwoVertex - distance
						}
					}
					// we add the accurate distance to totalDistance
					else {
						totalDistance += distance
						break
					}
				}
			}	
			// we add distance
			else if (index != 0){
				totalDistance += self.coordinates[index].distance(to: self.coordinates[index-1])
			}
		}

	
	}
}
