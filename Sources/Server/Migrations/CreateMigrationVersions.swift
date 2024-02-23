//
//  CreateMigrationVersions.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 1/29/23.
//

import FluentKit

/// A migration to create ``MigrationVersion`` records.
struct CreateMigrationVersions: AsyncMigration {
	
	func prepare(on database: any Database) async throws {
		try await database
			.schema(MigrationVersion.schema)
			.id()
			.field("schema_name", .string, .required)
			.field("version", .uint, .required, .sql(.default(0)))
			.create()
	}
	
	func revert(on database: any Database) async throws {
		try await database
			.schema(MigrationVersion.schema)
			.delete()
	}
	
}
