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

final class Route: Model, Content, Collection {
	
	static let schema = "routes"
	
	let startIndex = 0
	
	lazy var endIndex = self.coordinates.count - 1
	
	@ID var id: UUID?
	
	@Field(key: "coordinates") var coordinates: [Coordinate]
	
	init() { }
	
	init(from gpxRoute: GPXRoute) {
		self.coordinates = gpxRoute.points.compactMap { (gpxRoutePoint) in
			return Coordinate(from: gpxRoutePoint)
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
	
	func save(on database: Database) {
		self.forEach { (route) in
			_ = route.save(on: database)
		}
	}
	
}
