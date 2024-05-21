//
//  ScheduleController.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 1/10/24.
//

import Vapor

/// A structure that registers routes for the schedule.
/// - Important: This structure registers a route on the index path of its provided routes builder, so make sure to enclose it in a named routes group to avoid path collisions.
/// - Remark: In the context of this structure, the term “route” refers to an HTTP route, not a shuttle route.
struct ScheduleController: RouteCollection {
	
	/// Registers an HTTP route that redirects to the schedule information.
    /// - Parameter routes: A builder object for registering routes.
    /// - Throws: Throws an error if the route cannot be registered properly.
    
	func boot(routes: any RoutesBuilder) throws {
		routes.get(use: self.index(_:))
	}
	
	/// Redirects the client to a static JSON file that contains schedule information.
    /// - Parameter request: A `Request` object encapsulating details about the incoming request.
    /// - Returns: A `Response` object that performs the redirect to the schedule JSON file.
	private func index(_ request: Request) -> Response {
		return request.redirect(to: "/schedule.json")
	}
	
}
