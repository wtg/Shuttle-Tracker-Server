//
//  VersionedMigrator.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 1/29/23.
//

import FluentKit
import PostgresNIO

/// A migrator that automatically handles migrations across multiple schema versions.
struct VersionedMigrator {
	
	private let database: any Database
	
	/// Creates a versioned migrator.
	/// - Parameter database: The database on which to perform migrations.
	init(database: any Database) async throws {
		try await MigrationLog.migration.prepare(on: database).get() // Unlike most migrations, this one won’t fail if it’s executed multiple times.
		let migration = CreateMigrationVersions()
		let migrationLogs = try await MigrationLog
			.query(on: database)
			.all()
		let doMigrate = !migrationLogs.contains { (migrationLog) in
			return migrationLog.name == migration.name
		}
		if doMigrate {
			do {
				try await migration.prepare(on: database)
			} catch let error as PSQLError {
				if case .server = error.code {
					database.logger.log(level: .info, "Skipping preparation of the migration-versions table…")
				} else {
					throw error // Rethrow the error because we don’t know how to handle it here.
				}
			}
			let lastBatch = try await MigrationLog
				.query(on: database)
				.sort(\.$batch, .descending)
				.first()?
				.batch ?? 0
			try await MigrationLog(name: migration.name, batch: lastBatch + 1)
				.create(on: database)
		}
		self.database = database
	}
	
	/// Performs a migration to the latest schema version.
	/// - Parameter migration: The migration to perform.
	func migrate<MigrationType>(_ migration: MigrationType) async throws where MigrationType: VersionedAsyncMigration {
		self.database.logger.log(level: .info, "Migrating schema “\(MigrationType.ModelType.schema)”…")
		let version = try await migration.version(on: self.database)?.version ?? 0
		if version < MigrationType.ModelType.version {
			try await migration.prepare(on: database)
		} else if version > MigrationType.ModelType.version {
			try await migration.revert(on: database)
		}
	}
	
}
