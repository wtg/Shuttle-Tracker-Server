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
	
	/// Registers HTTP routes for retrieving shuttle stop data and manages individual stop details through a nested controller.
    /// - Parameter routes: A builder object for registering routes.
    /// - Throws: Throws an error if the routes cannot be registered properly.
	func boot(routes: any RoutesBuilder) throws {
		routes.get(use: self.read(_:))
		try routes.register(collection: StopController())
	}
	
	/// Retrieves all active shuttle stops from the database, ensuring each stop is returned only once.
    /// - Parameter request: A `Request` object encapsulating details about the incoming request.
    /// - Returns: An array of `Stop` objects representing active shuttle stops.
    /// - Throws: Throws an error if there is a failure in fetching the data from the database.
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
