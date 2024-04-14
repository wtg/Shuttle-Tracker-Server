//
//  WebRedirectsController.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 1/10/24.
//

import Vapor

/// A structure that registers routes for redirects to the Web client.
/// - Important: This structure registers a route on the index path of its provided routes builder, so make sure to enclose it in a named routes group to avoid path collisions.
/// - Remark: In the context of this structure, the term “route” refers to an HTTP route, not a shuttle route.
struct WebRedirectsController: RouteCollection {
	
	/// Registers HTTP routes for redirecting users to the main and beta versions of the Web client.
    /// - Parameter routes: A builder object for registering routes.
    /// - Throws: Throws an error if the routes cannot be registered properly.
	func boot(routes: any RoutesBuilder) throws {
		routes.get(use: self.index(_:))
		routes.get("beta", use: self.beta(_:))
	}
	
	/// Redirects to the main Web client page.
    /// - Parameter request: A `Request` object encapsulating details about the incoming request.
    /// - Returns: A `Response` object that performs a redirect to the main web client's URL.
    
	private func index(_ request: Request) -> Response {
        // Directs users to the main page of the Web client
		return request.redirect(to: "https://web.shuttletracker.app")
	}
	
	/// Redirects to the beta version of the Web client.
    /// - Parameter request: A `Request` object encapsulating details about the incoming request.
    /// - Returns: A `Response` object that performs a redirect to the beta version of the web client's URL.
	private func beta(_ request: Request) -> Response {
		// Directs users to the beta page of the Web client
		return request.redirect(to: "https://staging.web.shuttletracker.app")
	}
	
}
