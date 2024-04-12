//
//  AndroidRedirectsController.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 1/10/24.
//

import Vapor

/// A structure that registers routes for redirects to the Android app.
/// - Important: This structure registers a route on the index path of its provided routes builder, so make sure to enclose it in a named routes group to avoid path collisions.
/// - Remark: In the context of this structure, the term “route” refers to an HTTP route, not a shuttle route.
struct AndroidRedirectsController: RouteCollection {
	
	/// Registers routes for redirecting to the main and beta versions of the Android app.
    /// - Parameter routes: A builder object for registering routes
	func boot(routes: any RoutesBuilder) throws {
		routes.get(use: self.index(_:))
		routes.get("beta", use: self.beta(_:))
	}
	
	/// Redirects to the main Android app page on Google Play.
    /// - Parameter request: A `Request` object encapsulating details about the incoming request.
    /// - Returns: A `Response` object that performs a redirect to the app's page.
	private func index(_ request: Request) -> Response {
		return request.redirect(to: "https://play.google.com/store/apps/details?id=edu.rpi.shuttletracker")
	}
	
	/// Redirects to the beta version of the Android app page on Google Play.
    /// - Parameter request: A `Request` object encapsulating details about the incoming request.
    /// - Returns: A `Response` object that performs a redirect to the beta app's page.
	private func beta(_ request: Request) -> Response {
		return request.redirect(to: "https://play.google.com/store/apps/details?id=edu.rpi.shuttletracker")
	}
	
}
