//
//  SwiftUIRedirectsController.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 1/10/24.
//

import Vapor

/// A structure that registers routes for redirects to the SwiftUI app.
/// - Important: This structure registers a route on the index path of its provided routes builder, so make sure to enclose it in a named routes group to avoid path collisions.
/// - Remark: In the context of this structure, the term “route” refers to an HTTP route, not a shuttle route.
struct SwiftUIRedirectsController: RouteCollection {
	
	/// Registers HTTP routes for redirecting users to the main and beta versions of the SwiftUI app.
    /// - Parameter routes: A builder object for registering routes.
    /// - Throws: Throws an error if the routes cannot be registered properly.
    
	func boot(routes: any RoutesBuilder) throws {
		routes.get(use: self.index(_:))
		routes.get("beta", use: self.beta(_:))
	}
	
	/// Redirects to the main SwiftUI app page on the App Store.
    /// - Parameter request: A `Request` object encapsulating details about the incoming request.
    /// - Returns: A `Response` object that performs a redirect to the app's page on the App Store.
	private func index(_ request: Request) -> Response {
		return request.redirect(to: "https://apps.apple.com/us/app/shuttle-tracker/id1583503452")
	}
	
	/// Redirects to the beta version of the SwiftUI app on TestFlight.
    /// - Parameter request: A `Request` object encapsulating details about the incoming request.
    /// - Returns: A `Response` object that performs a redirect to the beta app's page on TestFlight.
	private func beta(_ request: Request) -> Response {
		return request.redirect(to: "https://testflight.apple.com/join/GsmZkfgd")
	}
	
}
