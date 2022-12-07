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
		guard let debug = LineString(self.coordinates)
			.closestCoordinate(to: location.coordinate)?
			.coordinate else { 
				return false }
		guard let distance = distance else {
			return false
		}
		return distance < Constants.isOnRouteThreshold
	}

	/// Calculates the total distance along a route given in meters from start to end back to start
	func measureTotalMetersAlongRoute() -> LocationDistance {
		let endRtePtLocation = self.coordinates.last;
		var distanceAlongRoute: LocationDistance = 0.0
		var endRtePtNotFound = true;
		// Measure the distance in meters from the start of the route to the end of the route representation
		for (index, rtept) in self.coordinates.enumerated() {
			if (index != 0) {
				distanceAlongRoute += rtept.distance(to: self.coordinates[index-1])
				// Measure the distance in meters from the end of the route representation back to the start of the route
				if (endRtePtNotFound) {
					distanceAlongRoute += rtept.distance(to: self.coordinates[index-1])
					if (endRtePtLocation == rtept) {
						endRtePtNotFound = false;
					}
				}
			}
		}
		return distanceAlongRoute
	}
	/// Calculates the total distance a bus has traveled along the route from the first rtept to the provided location
	/// - Parameter location: The location the bus is currently at
	/// - Returns: The distance the bus has traveled along the route or nil if the location is too far from the route
	func calculateDistanceAlongRoute(location: Bus.Location, locationHistory: [Bus.Location]) -> LocationDistance? {
		let RTELineString = LineString(self.coordinates)
		print("Calculate Distance Start: "+String(location.coordinate.latitude)+","+String(location.coordinate.longitude))
		guard let nearestRTEPT = RTELineString.closestVertex(to: location.coordinate) else {
			// A rtept could not be found along the route to the bus location
			print("Failed: A nearest rtept couldn't be found to this bus location")
			return nil
		}
		print("NearestRTEPT: From "+String(location.coordinate.latitude)+","+String(location.coordinate.longitude)+" to "+String(nearestRTEPT.latitude)+","+String(nearestRTEPT.longitude))
		guard let oldestBusLocation = locationHistory.first?.coordinate else {
			// There are not enough location points to determine the direction the bus is moving
			print("Failed: locationhistory doesn't even have one point")
			return nil
		}
		guard let oldestPassedRTEPT = RTELineString.closestVertex(to: oldestBusLocation) else {
			// A rtept could not be found along the route to the oldest bus location
			print("Failed: Oldest passed rtept couldn't be found")
			return nil
		}
		print("OldestRTEPT: From "+String(oldestBusLocation.latitude)+","+String(oldestBusLocation.longitude)+" to "+String(oldestPassedRTEPT.latitude)+","+String(oldestPassedRTEPT.longitude))
		guard let previousRTEPTIndex = RTELineString.find(vertex: oldestPassedRTEPT) else {
			// The index for the oldest passed rtept could not be found on the route
			print("Failed: Couldn't find index for oldest bus location pt")
			return nil
		}
		guard let currentRTEPTIndex = RTELineString.find(vertex: nearestRTEPT) else {
			// The index for the nearest rtept could not be found along this routes linestring
			print("Failed: Couldn't find index for nearest rtept")
			return nil
		}
		print("Starting Distance assignment after passing all checks")
		let directionIsReversed = previousRTEPTIndex > currentRTEPTIndex
		print("The direction is: " + (directionIsReversed ? "reversed" : "not reversed"))
		var distanceAlongRoute: LocationDistance = 0.0
		for (index, rtept) in self.coordinates.enumerated() {
			if (rtept == nearestRTEPT) {
				if (index == 0) { // Case: The first rtept in the route is the nearest rtept to the current bus location
					// Let us say there is an 'x' is either 'x1' or 'x2'.
					// Assume we have the following polyline:
					// |--x1--|--x2--|
					// ?      a      b
					// return the distance from the first rtept to the current location, 'x', since the bus must have just passed the first rtept to be on this rte
					distanceAlongRoute += nearestRTEPT.distance(to: location.coordinate) // distance(a,x)
				}
				else {
					// If the current rtept is the nearest rtept, determine if the reported bus location is to the left or right of the nearest rtept
					// (i.e. Assume we have the following polyline
					// |-----|-----| --> |--x1--|--x2--| --> This algorithm determines whether the current bus location, 'x' is either 'x1' or 'x2' relative to the nearest rtept, 'b'
					// a     b     c     a      b      c
					//
					// For brevity assume the following in all polyline cases:
					//		Let 'x' be either 'x1' or 'x2' which is determined by the case analysis
					// 		Let 'a' be the rtept before the nearest rtept in the entire route
					// 		Let 'b' be the nearest rtept in the entire route
					// 		Let 'c' be the rtept after the nearest rtept in the entire route
					//
					// This step is needed in order to determine whether the distance the bus has traveled includes 'a' to 'x1' or instead 'b' to 'x2'
					//
					// There are 3 cases:	1) distance(a,b) == distance(b,c)
					// 										2) distance(a,b) < distance(b,c)
					// 			 							3) distance(a,b) > distance(b,c) 

					let deltaToPreviousRTEPT = nearestRTEPT.distance(to: self.coordinates[index-1]) // distance(a,b)
					let deltaToNextRTEPT = nearestRTEPT.distance(to: self.coordinates[index+1]) // distance(b,c)
					var distance: LocationDistance = 0.0
					var busBeforeNearestRTEPT = true
					if (deltaToPreviousRTEPT == deltaToNextRTEPT) { // Case 1
						if (self.coordinates[index-1].distance(to: location.coordinate) < self.coordinates[index+1].distance(to: location.coordinate)){ //distance(a,x) < distance(c,x)
							// Assume the following polyline (for case 1):
							// |--x1--|--x2--| 
							// a      b      c
							// if distance(a,x) < distance(x,c) then x = x1 which implies the bus has just passed rtept 'a' and that we must sum the remaining distance from 'a' to x==x1
							distance += self.coordinates[index-1].distance(to: location.coordinate) // distance(a,x)
						}
						else {
							// Otherwise x == x2 which implies the bus has just passed rtept 'b' and that we must sum the remaining distance from 'b' to x==x2
							distance += nearestRTEPT.distance(to: location.coordinate) // distance(b,x)
							busBeforeNearestRTEPT = false
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
							distance = nearestRTEPT.distance(to: location.coordinate) // distance(b,x)
							busBeforeNearestRTEPT = false
						}
						else {
							// Otherwise x == x1 which implies the bus has just passed rtept 'a' and that we must sum the remaining distance from 'a' to x==x1
							distance = self.coordinates[index-1].distance(to: location.coordinate) // distance(a,x)
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
							distance = self.coordinates[index-1].distance(to: location.coordinate) // distance(a,x)
						}
						else {
							// Otherwise x == x2 which implies the bus has just passed rtept 'b' and that we must sum the remaining distance from 'b' to x==x2
							distance = nearestRTEPT.distance(to: location.coordinate) // distance(b,x)
							busBeforeNearestRTEPT = false
						}
					}
					if (directionIsReversed){
						// Assume we have the following polyline:
						// |--...-x1--|--x2-...--| (The ellipses represent that we may have polyline Case1, Case2, or Case3 since there is an arbitrarily long distance from 'a' to 'x1' and 'x2' to 'c') 
						// a          b          c
						//
						// If the direction is reversed then the bus has completed the route and is coming back to 'x'
						// Therefore there are 2 cases:
						//			1) The bus is before the nearest rtept, 'b', and 'x' is 'x1'
						// 			2) The bus is after the nearest rtept, 'b', and 'x' is 'x2'
						//
						//	Case 1)
						// 		distanceAlongRoute += dist(a,b) // We must sum the distance the bus took to complete the entire route which includes the rte segment, 'a' to 'b'
						//		distanceAlongRoute += dist(b,'x1') // The distance the bus has traveled on its way back from the completion of the route which is 'b' to 'x1'
						//
						//	Case 2)
						// 		distanceAlongRoute += dist(b,c) // We must sum the distance the bus took to complete the entire route which includes this rte segment, 'b' to 'c'
						//		distanceAlongRoute += dist(c,'x2') // The distance the bus has traveled on its way back from the completion of the route which is 'c' to 'x2'

						var distAlongRTESegment: LocationDistance = 0.0
						var distFromCurRTEPTToCurLocation: LocationDistance = 0.0
						if (busBeforeNearestRTEPT) { // Case 1
							distAlongRTESegment = self.coordinates[index-1].distance(to: self.coordinates[index]) // distance(a,b)
							// distance(b,'x1') = distance(a,b) - distance(a,'x1')
							distFromCurRTEPTToCurLocation = (distAlongRTESegment - distance) // distance(b,'x1')
						}
						else { // Case 2
							distAlongRTESegment = self.coordinates[index].distance(to: self.coordinates[index+1]) // distance(b,c)
							// distance(c,'x2') = distance(b,c) - distance(b,'x2')
							distFromCurRTEPTToCurLocation = (distAlongRTESegment - distance) // distance(c,'x2')
						}
						distanceAlongRoute += (distAlongRTESegment + distFromCurRTEPTToCurLocation)
						// Do not break because we still want to sum all of the rte segments from the start of the rte to the end of the rte
						// since the bus has completed the entire rte and is coming back to the start of the rte
					}
					else{
						distanceAlongRoute += distance
						break;
					}
				}
			}
			else if (index != 0) {
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
