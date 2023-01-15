//
//  CreateRoutes.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 10/20/20.
//

import Fluent

/// A migration to create `Route` records.
struct CreateRoutes: AsyncMigration {
	
	func prepare(on database: any Database) async throws {
		try await database
			.schema(Route.schema)
			.id()
			.field(
				"name",
				.string,
				.required
			)
			.field(
				"coordinates",
				.array(
					of: .custom(Coordinate.self)
				),
				.required
			)
			.field(
				"schedule",
				.dictionary,
				.required
			)
			.field(
				"color_name",
				.enum(
					DatabaseSchema.DataType.Enum(
						name: ColorName.sqlName,
						cases: ColorName.allCases.map(\.rawValue)
					)
				),
				.required
			)
			.create()
	}
	
	func revert(on database: any Database) async throws {
		try await database
			.schema(Route.schema)
			.delete()
	}
	
}
