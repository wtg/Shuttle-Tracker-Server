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
	
	func boot(routes: any RoutesBuilder) throws {
		routes.get(use: self.index(_:))
	}
	
	private func index(_: Request) -> UInt {
		return Constants.apiVersion
	}
	
}
