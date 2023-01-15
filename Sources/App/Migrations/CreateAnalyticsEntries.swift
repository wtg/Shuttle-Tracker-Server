//
//  CreateAnalyticsEntries.swift
//  Shuttle Tracker Server
//
//  Created by Mahi Pasarkar on 3/1/2022.
//

import Fluent

/// A migration to create `AnalyticsEntry` records.
struct CreateAnalyticsEntries: AsyncMigration {
	
	func prepare(on database: Database) async throws {
		try await database
			.schema(AnalyticsEntry.schema)
			.id()
			.field("user_id", .uuid)
			.field("date", .datetime, .required)
			.field("client_platform", .string, .required)
			.field("client_platform_version", .string)
			.field("app_version", .string)
			.field("board_bus_count", .int)
			.field("user_settings", .dictionary, .required)
			.create()
	}
	
	func revert(on database: Database) async throws {
		try await database
			.schema(AnalyticsEntry.schema)
			.delete()
	}
}
