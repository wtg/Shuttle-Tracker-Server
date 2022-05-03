//
//  CreateRoutes.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 10/20/20.
//

import Fluent

/// A migration to create `Route` records.
struct CreateRoutes: AsyncMigration {
	
	func prepare(on database: Database) async throws {
		try await database
			.schema(Route.schema)
			.id()
			.field("coordinates", .array(of: .custom(Coordinate.self)), .required)
			.field("schedule", .dictionary, .required)
			.create()
	}
	
	func revert(on database: Database) async throws {
		try await database
			.schema(Route.schema)
			.delete()
	}
	
}
