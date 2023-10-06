//
//  Stop.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 10/20/20.
//

import CoreGPX
import FluentKit
import JSONParser
import Vapor

/// A representation of a shuttle stop.
final class Stop: Equatable, Hashable, Model, Content {
	
	static let schema = "stops"
	
	@ID
	var id: UUID?
	
	/// The human-readable name of this stop.
	@Field(key: "name")
	var name: String
	
	/// The geospatial coordinate that indicates the physical location of this stop.
	@Field(key: "coordinate")
	var coordinate: Coordinate
	
	@Field(key: "schedule")
	var schedule: MapSchedule

	@Field(key: "is_by_request") 
	var isByRequest: Bool

	@Field(key: "route_id")
	var routeID: Set<UUID>

	init() { }
	
	/// Creates a stop object from a GPX waypoint.
	/// - Parameters:
	///   - gpxWaypoint: The GPX waypoint from which to create a stop object.
	///   - schedule: The schedule for when the stop will be active.
	///	  - route: The set of routes to associate each stop object with a routeID
	/// - Note: This initializer fails and returns `nil` if the provided GPX waypoint doesn’t contain sufficient information to create a stop object.
	init?(from gpxWaypoint: any GPXWaypointProtocol, withSchedule schedule: MapSchedule, selectingRoutesFrom allRoutes: Set<Route>) {
		guard let name = gpxWaypoint.name, let coordinate = Coordinate(from: gpxWaypoint), let isByRequest = gpxWaypoint.desc
		 else { 
			return nil
		}
		self.name = name
		self.coordinate = coordinate
		self.schedule = schedule
		self.isByRequest = (isByRequest == "Request Only")
		self.routeID = []
		for route in allRoutes {
			if let id = route.id{
				if (route.checkStopIsOnRoute(Coordinate: self.coordinate)) {
					self.routeID.insert(id)
				}
			}
		}
	}

	func hash(into hasher: inout Hasher) {
		hasher.combine(self.name) // Hashing the ID could potentially violate Hashable’s invariants when the ID is determined by the database, so we hash the name instead. This means that stop names must be globally unique, which doesn’t seem to be too far-fetched as an assumption/requirement.
	}
	
	static func == (lhs: Stop, rhs: Stop) -> Bool {
		return lhs.name == rhs.name && lhs.coordinate == rhs.coordinate
	}
}
