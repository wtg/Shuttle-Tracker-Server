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
		guard let distance else {
			return false
		}
		return distance < Constants.isOnRouteThreshold
	}
	
}
