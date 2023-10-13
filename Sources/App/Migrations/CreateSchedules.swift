//
//  CreateSchedules.swift
//  Shuttle Tracker Server
//
//  Created by Dylan Zhou on 10/06/23.
//

import Fluent

/// A migration to create `Schedule` records.
struct CreateSchedules: AsyncMigration {
	
	func prepare(on database: any Database) async throws {
		try await database
			.schema(Schedule.schema)
			.id()
			.field("name", .string, .required)
            .field("start", .date, .required)
            .field("end", .date, .required)
            .field("content", .array(of: .custom(ScheduleInfo.Content.self)), .required)
			.create()
	}
	
	func revert(on database: any Database) async throws {
		try await database
			.schema(Schedule.schema)
			.delete()
	}
	
}
