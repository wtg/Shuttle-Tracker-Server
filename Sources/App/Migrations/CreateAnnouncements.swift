//
//  CreateAnnouncements.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 11/16/21.
//

import Fluent

/// A migration to create `Announcement` records.
struct CreateAnnouncements: AsyncMigration {
	
	func prepare(on database: any Database) async throws {
		try await database
			.schema(Announcement.schema)
			.id()
			.field("subject", .string, .required)
			.field("body", .string, .required)
			.field("start", .datetime, .required)
			.field("end", .datetime, .required)
			.field("schedule_type", .string, .required)
			.field("signature", .data, .required)
			.create()
	}
	
	func revert(on database: any Database) async throws {
		try await database
			.schema(Announcement.schema)
			.delete()
	}
	
}

