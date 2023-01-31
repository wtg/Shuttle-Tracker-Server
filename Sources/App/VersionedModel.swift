//
//  VersionedModel.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 1/29/23.
//

import FluentKit

/// A database model with an associated schema version number
protocol VersionedModel: Model {
	
	/// The latest version number of this model’s schema.
	///
	/// This value should be incremented whenever the schema is changed. Set it to a lower value to revert the relevant database table or to `0` to delete the table entirely.
	/// - Important: Always implement appropriate preparation and reversion logic in the relevant migration when changing the schema and the version number.
	/// - Important: The initial version number should be `1`, not `0`. Setting it to `0` will either prevent the relevant database table from being created or cause it to be deleted.
	static var version: UInt { get }
	
}
