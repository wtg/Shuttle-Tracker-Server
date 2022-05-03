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
	
	/// The waypoint coordinates that define this route.
	@Field(key: "coordinates") var coordinates: [Coordinate]
	
	/// A schedule that determines when this route is active.
	@Field(key: "schedule") var schedule: MapSchedule
	
	init() { }
	
	/// Creates a route object from a GPX route.
	/// - Parameters:
	///   - gpxRoute: The GPX route from which to create a route object.
	///   - schedule: The schedule for when the route will be active.
	init(from gpxRoute: GPXRoute, withSchedule schedule: MapSchedule) {
		self.coordinates = gpxRoute.points.compactMap { (gpxRoutePoint) in
			return Coordinate(from: gpxRoutePoint)
		}
		self.schedule = schedule
	}
	
	/// Creates a route object from a GPX track segment.
	/// - Parameters:
	///   - gpxTrackSegment: The GPX track segment from which to create a route object.
	///   - schedule: The schedule for when the route will be active.
	init(from gpxTrackSegment: GPXTrackSegment, withSchedule schedule: MapSchedule) {
		self.coordinates = gpxTrackSegment.points.compactMap { (gpxTrackPoint) in
			return Coordinate(from: gpxTrackPoint)
		}
		self.schedule = schedule
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
	func checkIfValid(location: Bus.Location) -> Bool {
		let distance = LineString(self.coordinates)
			.closestCoordinate(to: location.coordinate)?
			.coordinate
			.distance(to: location.coordinate)
		guard let distance = distance else {
			return false
		}
		return distance < Constants.isOnRouteThreshold
	}
	
}
