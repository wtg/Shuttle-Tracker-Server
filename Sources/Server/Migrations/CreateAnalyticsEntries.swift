//
//  CreateAnalyticsEntries.swift
//  Shuttle Tracker Server
//
//  Created by Mahi Pasarkar on 3/1/2022.
//

import FluentKit

/// A migration to create ``AnalyticsEntry`` records.
struct CreateAnalyticsEntries: VersionedAsyncMigration {
	
	typealias ModelType = AnalyticsEntry
	
	func prepare(
		using schemaBuilder: SchemaBuilder,
		to version: UInt,
		enumFactory: (any DatabaseEnum.Type) async throws -> DatabaseSchema.DataType
	) async throws {
		switch version {
		case 0:
			fatalError("Can’t prepare migration to version 0!")
		case 1:
			try await schemaBuilder
				.id()
				.field("user_id", .uuid)
				.field("date", .datetime, .required)
				.field("client_platform", enumFactory(ClientPlatform.self), .required)
				.field("client_platform_version", .string)
				.field("app_version", .string)
				.field("board_bus_count", .int)
				.field("user_settings", .dictionary, .required)
				.create()
		case 2:
			try await schemaBuilder
				.field("event_type", .dictionary)
				.update()
		default:
			fatalError("Unknown migration version number!")
		}
	}
	
	func revert(using schemaBuilder: SchemaBuilder, to version: UInt) async throws {
		switch version {
		case 0:
			try await schemaBuilder.delete()
		case 1:
			try await schemaBuilder
				.deleteField("event_type")
				.update()
		default:
			fatalError("Unknown migration version number!")
		}
	}
}
