//
//  CreateLogs.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 10/30/22.
//

import FluentKit

/// A migration to create `Log` records.
struct CreateLogs: VersionedAsyncMigration {
	
	typealias ModelType = Log
	
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
				.field("content", .string, .required)
				.field("client_platform", enumFactory(ClientPlatform.self), .required)
				.field("date", .datetime, .required)
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
