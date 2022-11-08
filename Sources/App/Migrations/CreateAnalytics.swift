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
			.field("platform", .string)
            .field("osVersion", .string)
			.field("appVersion", .string, .required)
            .field("used_board", .bool, .required)
            .field("times_boarded", .int, .required)
            .field("user_settings", .dictionary)

			.create()
	}
	
	func revert(on database: Database) async throws {
		try await database
			.schema(AnalyticsEntry.schema)
			.delete()
	}
}