//
//  File.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 10/9/20.
//

import Foundation
import CoreGPX

/// A representation of a latitude-longitude geospatial coordinate pair.
struct Coordinate: Equatable, Codable {
	
	/// The latitude value.
	var latitude: Double
	
	/// The longitude value.
	var longitude: Double
	
	/// Numerically add the right coordinate's latitude and longitude values to the left coordinate's respective values in place.
	static func += (_ leftCoordinate: inout Coordinate, _ rightCoordinate: Coordinate) {
		leftCoordinate.latitude += rightCoordinate.latitude
		leftCoordinate.longitude += rightCoordinate.longitude
	}
	
	/// Numerically divide the left coordinate's latitude and longitude values by the right coordinate's respective values in place.
	static func /= (_ coordinate: inout Coordinate, _ divisor: Double) {
		coordinate.latitude /= divisor
		coordinate.longitude /= divisor
	}
	
	/// Create a coordinate representation.
	/// - Parameters:
	///   - latitude: The latitude value.
	///   - longitude: The longitude value.
	init(latitude: Double, longitude: Double) {
		self.latitude = latitude
		self.longitude = longitude
	}
	
	/// Create a coordinate representation from a GPX waypoint.
	/// - Parameter gpxWaypoint: The GPX waypoint from which to create a coordinate representation.
	/// - Note: This initializer fails and returns `nil` if the provided `GPXWaypointProtocol` instance doesn't contain sufficient information to create a coordinate representation.
	init?(from gpxWaypoint: GPXWaypointProtocol) {
		guard let latitude = gpxWaypoint.latitude, let longitude = gpxWaypoint.longitude else {
			return nil
		}
		self.init(latitude: latitude, longitude: longitude)
	}
	
}
