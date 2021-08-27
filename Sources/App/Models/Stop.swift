//
//  Stop.swift
//  Rensselaer Shuttle Server
//
//  Created by Gabriel Jacoby-Cooper on 10/20/20.
//

import Vapor
import Fluent
import JSONParser

final class Stop: Model, Content {
	
	static let schema = "stops"
	
	@ID(custom: "id", generatedBy: .user) var id: Int?
	
	@Field(key: "coordinate") var coordinate: Coordinate
	
	@Field(key: "name") var name: String
	
	init() { }
	
	init(id: Int, coordinate: Coordinate, name: String) {
		self.id = id
		self.coordinate = coordinate
		self.name = name
	}
	
}

extension Collection where Element == Stop {
	
	func save(on database: Database) {
		self.forEach { (stop) in
			_ = stop.save(on: database)
		}
	}
	
}

extension Array where Element == Stop {
	
	static func download(application: Application, _ stopsCallback: @escaping ([Stop]) -> Void) {
		_ = application.client.get("https://shuttles.rpi.edu/stops")
			.map { (response) in
				guard let length = response.body?.readableBytes, let data = response.body?.getData(at: 0, length: length) else {
					return
				}
				let parser = ArrayJSONParser(data)
				do {
					let stops = try parser.parse().enumerated().compactMap { (index, _) -> Stop? in
						let stopParser = parser[dictionaryAt: index]
						guard let id = stopParser?["id", as: Int.self], let latitude = stopParser?["latitude", as: Double.self], let longitude = stopParser?["longitude", as: Double.self] else {
							return nil
						}
						let coordinate = Coordinate(latitude: latitude, longitude: longitude)
						let name = stopParser?["name", as: String.self] ?? ""
						return Stop(id: id, coordinate: coordinate, name: name)
					}
					stopsCallback(stops)
				} catch {
					return
				}
			}
	}
	
}
