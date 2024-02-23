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
	
	func boot(routes: any RoutesBuilder) throws {
		routes.get(use: self.index(_:))
		routes.get("beta", use: self.beta(_:))
	}
	
	private func index(_ request: Request) -> Response {
		return request.redirect(to: "https://apps.apple.com/us/app/shuttle-tracker/id1583503452")
	}
	
	private func beta(_ request: Request) -> Response {
		return request.redirect(to: "https://testflight.apple.com/join/GsmZkfgd")
	}
	
}
