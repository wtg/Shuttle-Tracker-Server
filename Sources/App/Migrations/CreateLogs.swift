//
//  CreateLogs.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 10/30/22.
//

import Fluent

/// A migration to create `Log` records.
struct CreateLogs: AsyncMigration {
	
	func prepare(on database: any Database) async throws {
		try await database
			.schema(Log.schema)
			.id()
			.field("content", .string, .required)
			.field("date", .datetime, .required)
			.create()
	}
	
	func revert(on database: any Database) async throws {
		try await database
			.schema(Log.schema)
			.delete()
	}
	
}
