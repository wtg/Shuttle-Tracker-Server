//
//  CreateMilestones.swift
//  Shuttle Tracker Server
//
//  Jose Luchsinger
//

import Fluent

/// Creates milestone records on server setup.
struct CreateMilestones: AsyncMigration {
	
	func prepare(on database: Database) async throws {
		try await database
			.schema(Milestone.schema)
			.id()
			.field("short", .string, .required)
			.field("name", .string, .required)
			.field("description", .string, .required)
			.field("count", .int, .required)
			.field("goal", .array(of: .int), .required)
			.create()

			
	}
	
	func revert(on database: Database) async throws {
		try await database
			.schema(Milestone.schema)
			.delete()
	}
	
}

