//
//  CreateStops.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 10/20/20.
//

import Fluent

/// A migration to create `Stop` records.
struct CreateStops: AsyncMigration {
	
	func prepare(on database: any Database) async throws {
		try await database
			.schema(Stop.schema)
			.id()
			.field("name", .string, .required)
			.field("coordinate", .dictionary, .required)
			.field("schedule", .dictionary, .required)
			.field("isByRequest", .string, .required)
			.create()
	}
	
	func revert(on database: any Database) async throws {
		try await database
			.schema(Stop.schema)
			.delete()
	}
	
}
