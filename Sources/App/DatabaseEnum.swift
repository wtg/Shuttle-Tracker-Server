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
		guard case .enum(let `enum`) = try await builder.read() else {
			throw DatabaseEnumError.notAnEnum
		}
		for enumCase in self.allCases where !`enum`.cases.contains(enumCase.rawValue) {
			builder = builder.case(enumCase.rawValue)
		}
		if `enum`.cases.isEmpty {
			return try await builder.create()
		} else {
			
			return try await builder.update()
		}
	}
	
}

enum DatabaseEnumError: Error {
	
	case notAnEnum
	
	var localizedDescription: String {
		get {
			switch self {
			case .notAnEnum:
				return "The representation is not an enumeration."
			}
		}
	}
	
}
