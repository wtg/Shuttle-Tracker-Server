//
//  CreateStops.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 10/20/20.
//

import Fluent

struct CreateStops: AsyncMigration {
	
	func prepare(on database: Database) async throws {
		try await database.schema(Stop.schema)
			.id()
			.field("name", .string, .required)
			.field("coordinate", .dictionary, .required)
			.create()
	}
	
	func revert(on database: Database) async throws {
		try await database.schema(Stop.schema)
			.delete()
	}
	
}
