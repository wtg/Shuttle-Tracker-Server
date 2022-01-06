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
final class Stop: Model, Content {
	
	static let schema = "stops"
	
	@ID(custom: "id") var id: UUID?
	
	/// The human-readable name of this stop.
	@Field(key: "name") var name: String
	
	/// The geospatial coordinate that indicates the physical location of this stop.
	@Field(key: "coordinate") var coordinate: Coordinate
	
	init() { }
	
	/// Create a stop object from a GPX waypoint.
	/// - Parameter gpxWaypoint: The GPX waypoint from which to create a stop object.
	/// - Note: This initializer fails and returns `nil` if the provided `GPXWaypointProtocol` instance doesn't contain sufficient information to create a stop object.
	init?(from gpxWaypoint: GPXWaypointProtocol) {
		guard let name = gpxWaypoint.name, let coordinate = Coordinate(from: gpxWaypoint) else {
			return nil
		}
		self.name = name
		self.coordinate = coordinate
	}
	
}
