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
///
/// A route is represented as a sequence of geospatial coordinates.
final class Route: Model, Content, Collection {
	
	static let schema = "routes"
	
	let startIndex = 0
	
	lazy var endIndex = self.coordinates.count - 1
	
	@ID var id: UUID?
	
	/// The waypoint coordinates that define this route.
	@Field(key: "coordinates") var coordinates: [Coordinate]
	
	init() { }
	
	/// Creates a route object from a GPX route.
	/// - Parameter gpxRoute: The GPX route from which to create a route object.
	init(from gpxRoute: GPXRoute) {
		self.coordinates = gpxRoute.points.compactMap { (gpxRoutePoint) in
			return Coordinate(from: gpxRoutePoint)
		}
	}
	
	/// Creates a route object from a GPX track segment.
	/// - Parameter gpxTrackSegment: The GPX track segment from which to create a route object.
	init(from gpxTrackSegment: GPXTrackSegment) {
		self.coordinates = gpxTrackSegment.points.compactMap { (gpxTrackPoint) in
			return Coordinate(from: gpxTrackPoint)
		}
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
		return self.coordinates
			.enumerated()
			.compactMap { (offset, coordinate2) -> Double? in
				let coordinate1: Coordinate
				if offset == 0 {
					coordinate1 = self.coordinates.last!
				} else {
					coordinate1 = self.coordinates[offset - 1]
				}
				let (x0, y0) = location.coordinate.convertedForFlatGrid(centeredAtLatitude: CoordinateUtilities.centerLatitude)
				let (x1, y1) = coordinate1.convertedForFlatGrid(centeredAtLatitude: CoordinateUtilities.centerLatitude)
				let (x2, y2) = coordinate2.convertedForFlatGrid(centeredAtLatitude: CoordinateUtilities.centerLatitude)
				let a = y1 - y2
				let b = x2 - x1
				let c = x1 * y2 - x2 * y1
				let distance = abs(a * x0 + b * y0 + c) / sqrt(pow(a, 2) + pow(b, 2))
				return distance.isNaN ? nil : distance
			}
			.reduce(into: false) { (partialResult, distance) in
				if distance < 10 {
					partialResult = true
				}
			}
	}
	
}
