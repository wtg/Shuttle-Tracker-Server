//
//  CreateMilestones.swift
//  Shuttle Tracker Server
//
//  Created by Jose Luchsinger on 2/11/22.
//

import FluentKit

/// A migration to create ``Milestone`` records.
struct CreateMilestones: VersionedAsyncMigration {
	
	typealias ModelType = Milestone
	
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
				.field("name", .string, .required)
				.field("extended_description", .string, .required)
				.field("progress", .int, .required)
				.field("progress_type", .string, .required)
				.field("goals", .array(of: .int), .required)
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
