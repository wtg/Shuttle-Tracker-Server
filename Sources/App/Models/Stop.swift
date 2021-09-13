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

extension Collection where Element == Stop {
	
	/// Save each stop object in this collection.
	/// - Parameter database: The database on which to save the stop objects.
	func save(on database: Database) {
		self.forEach { (stop) in
			_ = stop.save(on: database)
		}
	}
	
}

//extension Array where Element == Stop {
//	
//	static func download(application: Application, _ stopsCallback: @escaping ([Stop]) -> Void) {
//		_ = application.client.get("http://shuttles.rpi.edu/stops")
//			.map { (response) in
//				guard let length = response.body?.readableBytes, let data = response.body?.getData(at: 0, length: length) else {
//					return
//				}
//				let parser = ArrayJSONParser(data)
//				do {
//					let stops = try parser.parse().enumerated().compactMap { (index, _) -> Stop? in
//						let stopParser = parser[dictionaryAt: index]
//						guard let id = stopParser?["id", as: Int.self], let latitude = stopParser?["latitude", as: Double.self], let longitude = stopParser?["longitude", as: Double.self] else {
//							return nil
//						}
//						let coordinate = Coordinate(latitude: latitude, longitude: longitude)
//						let name = stopParser?["name", as: String.self] ?? ""
//						return Stop(id: id, coordinate: coordinate, name: name)
//					}
//					stopsCallback(stops)
//				} catch {
//					return
//				}
//			}
//	}
//	
//}
