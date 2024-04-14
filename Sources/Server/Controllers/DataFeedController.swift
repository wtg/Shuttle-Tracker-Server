//
//  DataFeedController.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 1/12/24.
//

import Vapor

/// A structure that registers routes for the data-feed.
/// - Important: This structure registers a route on the index path of its provided routes builder, so make sure to enclose it in a named routes group to avoid path collisions.
/// - Remark: In the context of this structure, the term “route” refers to an HTTP route, not a shuttle route.
struct DataFeedController: RouteCollection {
	
	/// Registers a route that provides access to a data feed.
    /// - Parameter routes: A builder object for registering routes.
	func boot(routes: any RoutesBuilder) throws {
		routes.get(use: self.index(_:))
	}

	
    /// Returns the contents of a data feed URL as a string.
    /// - Parameter request: A `Request` object encapsulating details about the incoming request.
    /// - Returns: A string containing the contents of the data feed.
    /// - Throws: Throws an error if the contents cannot be loaded from the specified URL.
   
	private func index(_: Request) throws -> String {
		return try String(contentsOf: Constants.dataFeedURL)
	}
	
}
