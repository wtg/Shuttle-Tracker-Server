//
//  RoutesController.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 1/12/24.
//

import Vapor

/// A structure that registers routes for shuttle routes.
/// - Important: This structure registers routes on the index path of its provided routes builder, so make sure to enclose it in a named routes group to avoid path collisions.
/// - Remark: In the context of this structure, the term “route” could refer to either an HTTP route or a shuttle route, depending on the local context.
struct RoutesController: RouteCollection {
	
	func boot(routes: any RoutesBuilder) throws {
		// In the context of this method, the term “route” refers to an HTTP route, not a shuttle route.
		routes.get(use: self.read(_:))
	}
	
	private func read(_ request: Request) async throws -> [Route] {
		// In the context of this method, the term “route” refers to a shuttle route, not an HTTP route.
		return try await Route
			.query(on: request.db(.sqlite))
			.all()
			.filter { (route) in
				return route.schedule.isActive
			}
	}
	
}
