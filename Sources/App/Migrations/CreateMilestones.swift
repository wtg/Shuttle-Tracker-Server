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
			.field("name", .string, .required)
			.field("description", .string, .required)
			.field("count", Int, .required)
			.field("goal", [Int], .required)
			.create()
	}
	
	func revert(on database: Database) async throws {
		try await database
			.schema(Milestone.schema)
			.delete()
	}
	
}

