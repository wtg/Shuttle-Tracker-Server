//
//  StopsController.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 1/12/24.
//

import FluentKit
import Vapor

/// A structure that registers routes for shuttle stops.
/// - Important: This structure registers routes on the index path of its provided routes builder, so make sure to enclose it in a named routes group to avoid path collisions.
/// - Remark: In the context of this structure, the term “route” refers to an HTTP route, not a shuttle route.
struct StopsController: RouteCollection {
	
	func boot(routes: any RoutesBuilder) throws {
		routes.get(use: self.read(_:))
		try routes.register(collection: StopController())
	}
	
	private func read(_ request: Request) async throws -> [Stop] {
		let stops = try await Stop
			.query(on: request.db(.sqlite))
			.all()
			.filter { (stop) in
				return stop.schedule.isActive
			}
			.uniqued()
		return Array(stops)
	}

	private func nearest(_ request: Request) async throws -> [Bus] {
		if let latitude = request.query[Double.self, at: "latitude"], let longitude = request.query[Double.self, at: "longitude"] {
			// create a location type using the latitude, longtitude
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
			.filter { (bus) in
				return coordinateRoute.getTotalDistanceTraveled(location: bus.resolved!.location.coordinate) < coordinateRoute.getTotalDistanceTraveled(location: location)
			}
			return Array(buses)
		}
		throw Abort(.conflict)
	}
	
}
