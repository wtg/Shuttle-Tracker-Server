//
//  Route.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 10/9/20.
//

import Foundation
import Vapor
import Fluent
import CoreGPX
import JSONParser
import Turf

/// A representation of a shuttle route.
///
/// A route is represented as a sequence of geospatial coordinates.
final class Route: Model, Content, Collection {
	
	static let schema = "routes"
	
	let startIndex = 0
	
	lazy var endIndex = self.coordinates.count - 1
	
	@ID var id: UUID?
	
	/// The user-facing display name of this route.
	@Field(key: "name") var name: String
	
	/// The waypoint coordinates that define this route.
	@Field(key: "coordinates") var coordinates: [Coordinate]
	
	/// A schedule that determines when this route is active.
	@Field(key: "schedule") var schedule: MapSchedule
	
	/// The name of the color that clients should use to draw the route.
	@Field(key: "color_name") var colorName: ColorName
	
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
	init(name: String, coordinates: [Coordinate], schedule: MapSchedule, colorName: ColorName) {
		self.name = name
		self.coordinates = coordinates
		self.schedule = schedule
		self.colorName = colorName
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
		guard let distance = distance else {
			return false
		}
		return distance < Constants.isOnRouteThreshold
	}
	/// Calculates the total distance a bus has traveled along the route from the first rtept to the provided location
	/// - Parameter location: The location the bus is currently at
	/// - Returns: The distance the bus has traveled along the route or nil if the location is too far from the route
	func calculateDistanceAlongRoute(location: Bus.Location) -> Double? {
		let RTELineString = LineString(self.coordinates)
		guard let nearestRTEPT = RTELineString.closestVertex(to: location.coordinate) else {
			return nil
		}
		var distanceAlongRoute: Double = 0
		for (index, rtept) in self.coordinates.enumerated() {
			if (rtept == nearestRTEPT) {
				if (index == 0) {
					// Note that 'x' is either 'x1' or 'x2'.
					// Assume we have the following polyline:
					// |--x1--|--x2--|
					// ?      a      b
					// return the distance from the first rtept to the current location, 'x', since the bus must have just passed the first rtept or did not yet pass the first rtept
					distanceAlongRoute += nearestRTEPT.distance(to: location.coordinate) // distance(a,x)
				}
				else {
					// If the current rtept is the nearest rtept, determine if the reported bus location is to the left or right of the nearest rtept
					// (i.e. Assume we have the following polyline
					// |-----|-----| --> |--x1--|--x2--| --> This algorithm determines whether the current bus location, 'x' is either 'x1' or 'x2' relative to the nearest rtept which is 'b'
					// a     b     c     a      b      c
					// )
					// This step is needed in order to determine whether the distance the bus has traveled includes 'a' to 'x1' or instead 'b' to 'x2'
					
					// There are 3 cases:	1) distance(a,b) == distance(b,c)
					// 										2) distance(a,b) < distance(b,c)
					// 			 							3) distance(a,b) > distance(b,c) 

					let deltaToPreviousRTEPT = nearestRTEPT.distance(to: self.coordinates[index-1]) // distance(a,b)
					let deltaToNextRTEPT = nearestRTEPT.distance(to: self.coordinates[index+1]) // distance(b,c)
					if (deltaToPreviousRTEPT == deltaToNextRTEPT) { // Case 1
						if (self.coordinates[index-1].distance(to: location.coordinate) < self.coordinates[index+1].distance(to: location.coordinate)){ //distance(a,x) < distance(c,x)
							// Assume the following polyline (for case 1):
							// |--x1--|--x2--| 
							// a      b      c
							// if distance(a,x) < distance(x,c) then x = x1 which implies the bus has just passed rtept 'a' and that we must sum the remaining distance from 'a' to x==x1
							distanceAlongRoute += self.coordinates[index-1].distance(to: location.coordinate) // distance(a,x)
						}
						else {
							// Otherwise x == x2 which implies the bus has just passed rtept 'b' and that we must sum the remaining distance from 'b' to x==x2
							distanceAlongRoute += nearestRTEPT.distance(to: location.coordinate) // distance(b,x)
						}
					}
					else if (deltaToPreviousRTEPT < deltaToNextRTEPT){ // Case 2
						let delta1 = self.coordinates[index+1].distance(to: nearestRTEPT) - self.coordinates[index-1].distance(to: location.coordinate) // distance(b,c) - distance(a,x)
						let delta2 = self.coordinates[index+1].distance(to: nearestRTEPT) - self.coordinates[index-1].distance(to: nearestRTEPT) // distance(b,c) - distance(a,x)
						if (delta1 < delta2) {
							// Assume the following polyline (for case 2):
							// |--x1--|--x2-------| 
							// a      b           c
							// Suppose we have delta1 < delta2. By direct proof the following is true (for brevity assume distance(...) == d(...)):
							// delta1 = d(b,c) - d(a,x)
							// delta2 = d(b,c) - d(a,b)
							// delta1 < delta2 --> d(b,c) - d(a,x) < d(b,c) - d(a,b) --> -d(a,x) < -d(a,b) --> d(a,x) > d(a,b)
							// if delta1 < delta2 then d(a,x) > d(a,b) then x = x2 which implies the bus has just passed rtept 'b' and that we must sum the remaining distance from 'b' to x==x2
							distanceAlongRoute += nearestRTEPT.distance(to: location.coordinate) // distance(b,x)
						}
						else {
							// Otherwise x == x1 which implies the bus has just passed rtept 'a' and that we must sum the remaining distance from 'a' to x==x1
							distanceAlongRoute += self.coordinates[index-1].distance(to: location.coordinate) // distance(a,x)
						}
					}
					else { // Case 3
						let delta1 = self.coordinates[index-1].distance(to: nearestRTEPT) - self.coordinates[index+1].distance(to: location.coordinate) // distance(a,b) - distance(c,x)
						let delta2 = self.coordinates[index-1].distance(to: nearestRTEPT) - self.coordinates[index+1].distance(to: nearestRTEPT) // distance(a,b) - distance(b,c)
						if (delta1 < delta2) {
							// Assume the following polyline (for case 3):
							// |-------x1--|--x2--| 
							// a           b      c
							// Suppose we have delta1 < delta2. By direct proof the following is true (for brevity assume distance(...) == d(...)):
							// delta1 = d(a,b) - d(c,x)
							// delta2 = d(a,b) - d(b,c)
							// delta1 < delta2 --> d(a,b) - d(c,x) < d(a,b) - d(b,c) --> -d(c,x) < -d(b,c) --> d(c,x) > d(b,c)
							// if delta1 < delta2 then d(c,x) > d(b,c) then x = x1 which implies the bus has just passed rtept 'a' and that we must sum the remaining distance from 'a' to x==x1
							distanceAlongRoute += self.coordinates[index-1].distance(to: location.coordinate) // distance(a,x)
						}
						else {
							// Otherwise x == x2 which implies the bus has just passed rtept 'b' and that we must sum the remaining distance from 'b' to x==x2
							distanceAlongRoute += nearestRTEPT.distance(to: location.coordinate) // distance(b,x)
						}
					}
				}
				break;
			}
			else if (index != 0){
				// cumulatively sum the polyline distance from the previous rtept to the current rtept
				distanceAlongRoute += rtept.distance(to: self.coordinates[index-1])
				print("From ("+String(self.coordinates[index-1].latitude)+","+String(self.coordinates[index-1].longitude)+") to ("+String(rtept.latitude)+","+String(rtept.longitude)+")")
				print("Has distance: "+String(rtept.distance(to: self.coordinates[index-1])))
				print("Total Distance so far: "+String(distanceAlongRoute))
			} 
		}
		return distanceAlongRoute
	}
}
