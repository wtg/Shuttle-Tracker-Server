//
//  Route.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 10/9/20.
//

import Vapor
import Fluent
import CoreGPX
import JSONParser

/// A representation of a shuttle route.
final class Route: Model, Content, Collection {
	
	static let schema = "routes"
	
	let startIndex = 0
	
	lazy var endIndex = self.coordinates.count - 1
	
	@ID var id: UUID?
	
	/// The waypoint coordinates that define this route.
	@Field(key: "coordinates") var coordinates: [Coordinate]
	
	init() { }
	
	/// Create a route representation from a GPX route.
	/// - Parameter gpxRoute: The GPX route from which to create a route representation.
	init(from gpxRoute: GPXRoute) {
		self.coordinates = gpxRoute.points.compactMap { (gpxRoutePoint) in
			return Coordinate(from: gpxRoutePoint)
		}
	}
	
	init(from gpxTrackSegment: GPXTrackSegment) {
		self.coordinates = gpxTrackSegment.points.compactMap { (gpxTrackPoint) in
			return Coordinate(from: gpxTrackPoint)
		}
	}
	
	subscript(_ position: Int) -> Coordinate {
		return self.coordinates[position]
	}
	
	func index(after oldIndex: Int) -> Int {
		return oldIndex + 1
	}
	
}

extension Collection where Element == Route {
	
	/// Save each route object in this collection.
	/// - Parameter database: The database on which to save the route objects.
	func save(on database: Database) {
		self.forEach { (route) in
			_ = route.save(on: database)
		}
	}
	
}
