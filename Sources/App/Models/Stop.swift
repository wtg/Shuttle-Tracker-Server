//
//  Stop.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 10/20/20.
//

import Vapor
import Fluent
import CoreGPX
import JSONParser

/// A representation of a shuttle stop.
final class Stop: Equatable, Hashable, Model, Content {
	
	static let schema = "stops"
	
	@ID(custom: "id") var id: UUID?
	
	/// The human-readable name of this stop.
	@Field(key: "name") var name: String
	
	/// The geospatial coordinate that indicates the physical location of this stop.
	@Field(key: "coordinate") var coordinate: Coordinate
	
	@Field(key: "schedule") var schedule: MapSchedule
	
	init() { }
	
	/// Creates a stop object from a GPX waypoint.
	/// - Parameters:
	///   - gpxWaypoint: The GPX waypoint from which to create a stop object.
	///   - schedule: The schedule for when the stop will be active.
	/// - Note: This initializer fails and returns `nil` if the provided GPX waypoint doesn’t contain sufficient information to create a stop object.
	init?(from gpxWaypoint: any GPXWaypointProtocol, withSchedule schedule: MapSchedule) {
		guard let name = gpxWaypoint.name, let coordinate = Coordinate(from: gpxWaypoint) else {
			return nil
		}
		self.name = name
		self.coordinate = coordinate
		self.schedule = schedule
	}
	
	func hash(into hasher: inout Hasher) {
		hasher.combine(self.name) // Hashing the ID could potentially violate Hashable’s invariants when the ID is determined by the database, so we hash the name instead. This means that stop names must be globally unique, which doesn’t seem to be too far-fetched as an assumption/requirement.
	}
	
	static func == (_ lhs: Stop, _ rhs: Stop) -> Bool {
		return lhs.name == rhs.name && lhs.coordinate == rhs.coordinate
	}
	
}
