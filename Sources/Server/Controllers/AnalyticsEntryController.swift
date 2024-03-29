//
//  AnalyticsEntryController.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 1/12/24.
//

import Vapor

/// A structure that registers routes for managing individual analytics entries.
/// - Remark: In the context of this structure, the term “route” refers to an HTTP route, not a shuttle route.
struct AnalyticsEntryController: RouteCollection {
	
	func boot(routes: any RoutesBuilder) throws {
		routes.group(":id") { (routes) in
			routes.get(use: self.read(_:))
		}
	}
	
	private func read(_ request: Request) async throws -> AnalyticsEntry {
		let entry = try await AnalyticsEntry.find(
			request.parameters.get("id"),
			on: request.db(.psql)
		)
		guard let entry else {
			throw Abort(.notFound)
		}
		return entry
	}
	
}
