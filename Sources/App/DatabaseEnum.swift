//
//  DatabaseEnum.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 1/14/23.
//

import Fluent

/// An enumeration that can be represented in a SQL database via Fluent.
protocol DatabaseEnum: CaseIterable {
	
	/// The name of this enumeration.
	static var name: String { get }
	
	/// Creates a database representation of this enumeration.
	/// - Parameter database: The database in which to create the representation.
	/// - Returns: The representation.
	static func representation(for database: some Database) async throws -> DatabaseSchema.DataType
	
}

extension DatabaseEnum where Self: RawRepresentable, RawValue == String {
	
	static func representation(for database: some Database) async throws -> DatabaseSchema.DataType {
		var builder = database.enum(self.name)
		for enumCase in self.allCases {
			builder = builder.case(enumCase.rawValue)
		}
		return try await builder.create()
	}
	
}
