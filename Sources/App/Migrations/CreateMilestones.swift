//
//  CreateMilestones.swift
//  Shuttle Tracker Server
//
//  Created by Jose Luchsinger on 2/11/22.
//

import Fluent

/// A migration to create `Milestone` records.
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

