//
//  VersionController.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 1/10/24.
//

import Vapor

/// A structure that registers routes for the API version number.
/// - Important: This structure registers a route on the index path of its provided routes builder, so make sure to enclose it in a named routes group to avoid path collisions.
/// - Remark: In the context of this structure, the term “route” refers to an HTTP route, not a shuttle route.
struct VersionController: RouteCollection {
	
	/// Registers an HTTP route that provides the API version number.
    /// - Parameter routes: A builder object for registering routes.
    /// - Throws: Throws an error if the route cannot be registered properly.
	func boot(routes: any RoutesBuilder) throws {
		routes.get(use: self.index(_:))
	}

	/// Provides the current version number of the API.
    /// - Parameter request: A `Request` object encapsulating details about the incoming request.
    /// - Returns: An unsigned integer representing the API version number.
	private func index(_: Request) -> UInt {
		return Constants.apiVersion
	}
	
}
