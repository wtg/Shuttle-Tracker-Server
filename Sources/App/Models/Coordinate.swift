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
	
	/// Numerically divides the right coordinate’s latitude and longitude values to the left coordinate’s respective values in place.
	static func += (_ lhs: inout Coordinate, _ rhs: Coordinate) {
		lhs.latitude += rhs.latitude
		lhs.longitude += rhs.longitude
	}
	
	/// Numerically divides the left coordinate’s latitude and longitude values by the right coordinate’s respective values in place.
	static func /= (_ lhs: inout Coordinate, _ rhs: Double) {
		lhs.latitude /= rhs
		lhs.longitude /= rhs
	}
	
	/// Creates a coordinate representation.
	/// - Parameters:
	///   - latitude: The latitude value.
	///   - longitude: The longitude value.
	init(latitude: Double, longitude: Double) {
		self.latitude = latitude
		self.longitude = longitude
	}
	
	/// Creates a coordinate representation from a GPX waypoint.
	///
	/// This initializer fails and returns `nil` if the provided GPX waypoint doesn’t contain sufficient information to create a coordinate representation.
	/// - Parameter gpxWaypoint: The GPX waypoint from which to create a coordinate representation.
	init?(from gpxWaypoint: GPXWaypointProtocol) {
		guard let latitude = gpxWaypoint.latitude, let longitude = gpxWaypoint.longitude else {
			return nil
		}
		self.init(latitude: latitude, longitude: longitude)
	}
	
	/// Converts this geospatial coordinate pair into an x-y coordinate pair by projecting it onto a flat plane.
	///
	/// Since a geospatial coordinate pair represents a position on a sphere, it can’t be converted losslessly to a planar coordinate pair. This method generates approximate planar coordinates that are suitable for use in relatively small geographic regions.
	/// - Parameter centerLatitude: The latitude line that should be assumed tangential to the planar projection.
	/// - Returns: An x-y coordinate pair that represents the projected position on a flat plane. The values in the tuple are in meters.
	func convertedForFlatGrid(centeredAtLatitude centerLatitude: Double) -> (x: Double, y: Double) {
		let r = 6.3781E6
		let x = r * self.longitude * cos(centerLatitude)
		let y = r * self.latitude
		return (x: x, y: y)
	}
	
}
