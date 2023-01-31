//
//  CreateAnnouncements.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 11/16/21.
//

import FluentKit

/// A migration to create `Announcement` records.
struct CreateAnnouncements: VersionedAsyncMigration {
	
	typealias ModelType = Announcement
	
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
				.field("subject", .string, .required)
				.field("body", .string, .required)
				.field("start", .datetime, .required)
				.field("end", .datetime, .required)
				.field("schedule_type", .string, .required)
				.field("signature", .data, .required)
				.create()
		default:
			fatalError("Unknown migration version number!")
		}
	}
	
	func revert(using schemaBuilder: SchemaBuilder, to version: UInt) async throws {
		switch version {
		case 0:
			try await schemaBuilder.delete()
		default:
			fatalError("Unknown migration version number!")
		}
	}
	
}
