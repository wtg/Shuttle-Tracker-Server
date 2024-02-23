//
//  VersionedAsyncMigration.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 1/29/23.
//

import FluentKit

/// An asynchronous migration that automatically migrates across multiple schema versions.
///
/// The migrator incrementally invokes ``prepare(using:to:enumFactory:)`` or ``revert(using:to:)`` to migrate the schema for the associated model type to the version number that’s one greater or one less, respectively, than the current version number until the target version number is reached. Therefore, the implementations of ``prepare(using:to:enumFactory:)`` and ``revert(using:to:)`` should perform just a single version migration per invocation. A good way to implement these methods is to use a `switch` statement to switch on the specified version number. It’s acceptable to throw an error or to invoke `fatalError(_:file:line:)` if the specified version number is unrecognized.
/// - Remark: This protocol doesn’t inherit from Fluent’s own `AsyncMigration` protocol because it’s incompatible with Fluent’s native migrator. Use ``VersionedMigrator`` instead.
protocol VersionedAsyncMigration {
	
	/// The versioned model type that’s represented in the database table on which this migration operates.
	associatedtype ModelType: VersionedModel
	
	/// Migrates forward the database table that’s associated with the specified schema.
	/// - Precondition: The current migration version number equals`version - 1`.
	/// - Parameters:
	///   - schemaBuilder: The schema builder to use to declare and to perform the forward migration.
	///   - version: The schema version number to which to migrate the associated database table.
	///   - enumFactory: A closure that generates a database representation of an enumeration type.
	func prepare(
		using schemaBuilder: SchemaBuilder,
		to version: UInt,
		enumFactory: (any DatabaseEnum.Type) async throws -> DatabaseSchema.DataType
	) async throws
	
	/// Migrates backward the database table that’s associated with the specified schema.
	/// - Precondition: The current migration version number equals `version + 1`.
	/// - Parameters:
	///   - schemaBuilder: The schema builder to use to declare and to perform the backward migration.
	///   - version: The schema version number to which to migrate the associated database table.
	func revert(using schemaBuilder: SchemaBuilder, to version: UInt) async throws
	
}

extension VersionedAsyncMigration {
	
	func prepare(on database: some Database) async throws {
		let migrationVersion = try await self.version(on: database) ?? MigrationVersion(schemaName: ModelType.schema, version: 0)
		while migrationVersion.version < ModelType.version {
			database.logger.log(level: .info, "\tMigrating schema “\(ModelType.schema)” from version \(migrationVersion.version) to \(migrationVersion.version + 1)…")
			migrationVersion.version += 1
			try await self.prepare(using: database.schema(ModelType.schema), to: UInt(migrationVersion.version)) { (enumType) in
				return try await enumType.representation(for: database)
			}
			try await migrationVersion.save(on: database)
		}
	}
	
	func revert(on database: some Database) async throws {
		let migrationVersion = try await self.version(on: database) ?? MigrationVersion(schemaName: ModelType.schema, version: 0)
		while migrationVersion.version > ModelType.version {
			database.logger.log(level: .info, "\tMigrating schema “\(ModelType.schema)” from version \(migrationVersion.version) to \(migrationVersion.version - 1)…")
			migrationVersion.version -= 1
			try await self.revert(using: database.schema(ModelType.schema), to: UInt(migrationVersion.version))
			try await migrationVersion.save(on: database)
		}
	}
	
	/// The latest migration version for the database table that’s associated with the schema on which this migration operates.
	///
	/// This method returns the latest migration version _of which the database is aware_, not the latest migration version as defined in the source code. Therefore, it’s useful for figuring out how to migrate the current database schema to match the latest migration version in the source code.
	/// - Parameter database: The database on which to look up the latest migration version.
	/// - Returns: The latest migration version.
	func version(on database: some Database) async throws -> MigrationVersion? {
		return try await MigrationVersion
			.query(on: database)
			.filter(\.$schemaName == ModelType.schema)
			.sort(\.$version, .descending)
			.first()
	}
	
}
