//
//  Route.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 10/9/20.
//

import Vapor
import Fluent
import JSONParser

final class Route: Model, Content, Collection {
	
	static let schema = "routes"
	
	let startIndex = 0
	
	lazy var endIndex = self.coordinates.count - 1
	
	@ID var id: UUID?
	
	@Field(key: "coordinates") var coordinates: [Coordinate]
	
	@Field(key: "stopIDs") var stopIDs: [Int]
	
	init() { }
	
	init(_ coordinates: [Coordinate] = [], stopIDs: [Int]) {
		self.coordinates = coordinates
		self.stopIDs = stopIDs
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

extension Array where Element == Route {
	
	static func download(application: Application, _ routesCallback: @escaping ([Route]) -> Void) {
		_ = application.client.get("https://shuttles.rpi.edu/routes")
			.map { (response) in
				guard let length = response.body?.readableBytes, let data = response.body?.getData(at: 0, length: length) else {
					return
				}
				let parser = ArrayJSONParser(data)
				do {
					let routes = try parser.parse().enumerated().map { (index, _) -> Route in
						let routeParser = parser[dictionaryAt: index]
						let coordinates = routeParser?["points", as: [[String: Double]].self]?.compactMap { (object) -> Coordinate? in
							guard let latitude = object["latitude"], let longitude = object["longitude"] else {
								return nil
							}
							return Coordinate(latitude: latitude, longitude: longitude)
						} ?? []
						let stopIDs = routeParser?["stop_ids", as: [Int].self] ?? []
						return Route(coordinates, stopIDs: stopIDs)
					}
					routesCallback(routes)
				} catch {
					return
				}
			}
	}
	
}
