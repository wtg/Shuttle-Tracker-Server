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
			.schema(Analytics.schema)
			.field("uuid", .string, .required)
			.field("date_sent", .datetime, .required) //may change this to .datetime
			.field("platform", .string, .required)
            .field("version", .string, .required)
            .field("used_board", .bool, .required)
            .field("times_boarded", .int, .required)
            .field("user_settings", .custom(AnalyticsEntry.UserSettings.self), .required)
			.create()
	}
	
	func revert(on database: Database) async throws {
		try await database
			.schema(Analytics.schema)
			.delete()
	}



}