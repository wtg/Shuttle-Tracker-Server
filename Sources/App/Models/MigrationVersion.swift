//
//  MigrationVersion.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 1/29/23.
//

import FluentKit

final class MigrationVersion: Model {
	
	static let schema = "migrationversions"
	
	@ID
	var id: UUID?
	
	@Field(key: "schema_name")
	var schemaName: String
	
	@Field(key: "version")
	var version: Int
	
	/// Initializes an invalid migration version.
	/// - Warning: Do not use this initializer!
	init() { }
	
	init(schemaName: String, version: Int) {
		self.schemaName = schemaName
		self.version = version
	}
	
}
