//
//  File.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 10/9/20.
//

import Foundation
import CoreGPX

struct Coordinate: Equatable, Codable {
	
	var latitude: Double
	
	var longitude: Double
	
	static func += (_ leftCoordinate: inout Coordinate, _ rightCoordinate: Coordinate) {
		leftCoordinate.latitude += rightCoordinate.latitude
		leftCoordinate.longitude += rightCoordinate.longitude
	}
	
	static func /= (_ coordinate: inout Coordinate, _ divisor: Double) {
		coordinate.latitude /= divisor
		coordinate.longitude /= divisor
	}
	
	init(latitude: Double, longitude: Double) {
		self.latitude = latitude
		self.longitude = longitude
	}
	
	init?(from gpxWaypoint: GPXWaypointProtocol) {
		guard let latitude = gpxWaypoint.latitude, let longitude = gpxWaypoint.longitude else {
			return nil
		}
		self.init(latitude: latitude, longitude: longitude)
	}
	
}
