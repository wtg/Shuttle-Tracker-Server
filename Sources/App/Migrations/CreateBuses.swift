//
//  CreateBuses.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 9/21/20.
//

import Fluent

struct CreateBuses: AsyncMigration {
	
	func prepare(on database: Database) async throws {
		try await database.schema(Bus.schema)
			.id()
			.field("locations", .array(of: .custom(Bus.Location.self)), .required)
			.field("congestion", .int)
			.create()
	}
	
	func revert(on database: Database) async throws {
		try await database.schema(Bus.schema)
			.delete()
	}
	
}
