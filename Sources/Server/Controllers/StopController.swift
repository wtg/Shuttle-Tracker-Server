//
//  StopController.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 1/12/24.
//

import Vapor

/// A structure that registers routes for managing individual shuttle stops.
/// - Remark: In the context of this structure, the term “route” refers to an HTTP route, not a shuttle route.
struct StopController: RouteCollection {
	
	/// Registers HTTP routes that manage access to information about individual shuttle stops.
    /// - Parameter routes: A builder object for registering routes.
    /// - Throws: Throws an error if the routes cannot be registered properly.
	func boot(routes: any RoutesBuilder) throws {
		routes.group(":shortname") { (routes) in
			routes.get(use: self.read(_:))
		}
	}

	/// Provides a placeholder response for a shuttle stop based on its short name. This method needs to be implemented to return actual stop information.
    /// - Parameter request: A `Request` object encapsulating details about the incoming request, including the short name of the shuttle stop.
    /// - Returns: A temporary redirect response as a placeholder until actual implementation is completed.
	private func read(_ request: Request) -> Response {
		// TODO: Return something that’s actually useful
		return request.redirect(to: "/", redirectType: .temporary)
	}
	
}
