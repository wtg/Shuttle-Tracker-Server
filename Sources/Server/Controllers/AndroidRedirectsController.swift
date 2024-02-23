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
	
	func boot(routes: any RoutesBuilder) throws {
		routes.get(use: self.index(_:))
		routes.get("beta", use: self.beta(_:))
	}
	
	private func index(_ request: Request) -> Response {
		return request.redirect(to: "https://play.google.com/store/apps/details?id=edu.rpi.shuttletracker")
	}
	
	private func beta(_ request: Request) -> Response {
		return request.redirect(to: "https://play.google.com/store/apps/details?id=edu.rpi.shuttletracker")
	}
	
}
