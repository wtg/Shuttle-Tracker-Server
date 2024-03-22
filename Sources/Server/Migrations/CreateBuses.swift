//
//  CreateBuses.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 9/21/20.
//

import Fluent

/// A migration to create ``Bus`` records.
struct CreateBuses: AsyncMigration {
	
	func prepare(on database: any Database) async throws {
		try await database
			.schema(Bus.schema)
			.id()
			.field("locations", .array(of: .custom(Bus.Location.self)), .required)
			.field("congestion", .int)
			.field("route_id", .uuid)
			.field("meters_along_route", .double)
			// .field("previous_known_location", .custom(Bus.Resolved.self))
			.field("previous_locations", .array(of: .custom(Bus.Resolved.self)), .required)
			.foreignKey("route_id", references: "routes", "id", onDelete: .setNull)
			.create()
	}
	
	func revert(on database: any Database) async throws {
		try await database
			.schema(Bus.schema)
			.delete()
	}
	
}
