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
	
	func boot(routes: any RoutesBuilder) throws {
		routes.group(":shortname") { (routes) in
			routes.get(use: self.read(_:))
		}
	}
	
	private func read(_ request: Request) -> Response {
		// TODO: Return something that’s actually useful
		return request.redirect(to: "/", redirectType: .temporary)
	}
	
}
