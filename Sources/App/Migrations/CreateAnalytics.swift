//
//  CreateAnalytics.swift
//  Shuttle Tracker Server
//
//  Created by Mahi Pasarkar on 3/1/2022.
//

import Fluent

//Migration to create 'Analytics' Methods
struct CreateAnalytics: AsyncMigration {

    func prepare(on database: Database) async throws {
		try await database
			.schema(AnalyticsEntry.schema)
			.id()

			.field("user_id", .string)
			.field("date_sent", .datetime, .required)
			.field("platform", .string, .required)
            .field("osVersion", .string, .required)
			.field("appVersion", .string)
            .field("used_board", .bool)
            .field("times_boarded", .int)
            .field("user_settings", .dictionary, .required)

			.create()
	}
	
	func revert(on database: Database) async throws {
		try await database
			.schema(AnalyticsEntry.schema)
			.delete()
	}
}