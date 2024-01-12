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
	
	func boot(routes: any RoutesBuilder) throws {
		routes.get(use: self.index(_:))
		routes.get("beta", use: self.beta(_:))
	}
	
	private func index(_ request: Request) -> Response {
		return request.redirect(to: "https://web.shuttletracker.app")
	}

	private func beta(_ request: Request) -> Response {
		return request.redirect(to: "https://staging.web.shuttletracker.app")
	}
	
}
