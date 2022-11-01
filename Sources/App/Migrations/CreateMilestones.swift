//
//  CreateMilestones.swift
//  Shuttle Tracker Server
//
//  Created by Jose Luchsinger on 2/11/22.
//

import Fluent

/// A migration to create `Milestone` records.
struct CreateMilestones: AsyncMigration {
	
	func prepare(on database: any Database) async throws {
		try await database
			.schema(Milestone.schema)
			.id()
			.field("name", .string, .required)
			.field("extended_description", .string, .required)
			.field("progress", .int, .required)
			.field("progress_type", .string, .required)
			.field("goals", .array(of: .int), .required)
			.field("signature", .data, .required)
			.create()
	}
	
	func revert(on database: any Database) async throws {
		try await database
			.schema(Milestone.schema)
			.delete()
	}
	
}
