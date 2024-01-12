//
//  StopsController.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 1/12/24.
//

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
	
}
