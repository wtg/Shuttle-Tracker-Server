//
//  BusesController.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 1/12/24.
//

import Vapor

/// A structure that registers routes for shuttle buses.
/// - Important: This structure registers routes on the index path of its provided routes builder, so make sure to enclose it in a named routes group to avoid path collisions.
/// - Remark: Unless otherwise specified, in the context of this structure, the term “route” refers to an HTTP route, not a shuttle route.
struct BusesController<DecoderType>: RouteCollection where DecoderType: ContentDecoder {
	
	private let decoder: DecoderType
	
	init(decoder: DecoderType) {
		self.decoder = decoder
	}
	
	func boot(routes: any RoutesBuilder) throws {
		routes.get(use: self.read(_:))
		routes.get("all", use: self.all(_:))
		try routes.register(collection: BusController(decoder: self.decoder))
	}
	
	private func read(_ request: Request) async throws -> [Bus.Resolved] {
		// In the context of this method, the term “route” refers to a shuttle route, not an HTTP route.
		if let latitude = request.query[Double.self, at: "latitude"], 
		let longitude = request.query[Double.self, at: "longitude"] {
			try await nearest(request, latitude: latitude, longitude: longitude)
		}
		let routes = try await Route
			.query(on: request.db(.sqlite))
			.all()
			.filter { (route) in
				return route.schedule.isActive
			}
		return try await Bus
			.query(on: request.db(.sqlite))
			.all()
			.compactMap { (bus) in
				return bus.resolved
			}
			.filter { (resolved) in
				return !routes.allSatisfy { (route) in
					return !route.checkIsOnRoute(location: resolved.location)
				}
			}
	}
	
	private func all(_: Request) -> Set<Int> {
		return Buses.shared.allBusIDs
	}

	private func nearest(_ request: Request, latitude: Double, longitude: Double) async throws -> [Int:Int] {
			// create a Coordinate object using the latitude, longtitude
			let location: Coordinate = Coordinate(latitude: latitude, longitude: longitude)
			// get the route to determine the distance
			let routes = try await Route
			.query(on: request.db(.sqlite))
			.all()
			.filter { (route) in
				return (route.schedule.isActive && route.checkIsNearby(location: location))
			}
			let coordinateRoute: Route = routes.first!

			// filter the buses that are behind the location given
			let buses = try await Bus
			.query(on: request.db(.sqlite))
			.all()
			.compactMap { (bus) in
				return bus.resolved
			}
			.filter { (resolved) in
				return coordinateRoute.getTotalDistanceTraveled(location: resolved.location.coordinate) < coordinateRoute.getTotalDistanceTraveled(location: location)
			}

			// return the ids of the buses
			var busIDs: [Int:Int] = [Int:Int]()
			for bus in buses {
				let ETA: Int = calculateETA(busLocation: bus.location.coordinate, destination: location)
				busIDs[bus.id] = ETA
			}
			return busIDs
	}
	
}
