//
//  CreateStops.swift
//  Rensselaer Shuttle Server
//
//  Created by Gabriel Jacoby-Cooper on 10/20/20.
//

import Fluent

struct CreateStops: Migration {
	
	func prepare(on database: Database) -> EventLoopFuture<Void> {
		return database.schema(Stop.schema)
			.id()
			.field("coordinate", .dictionary, .required)
			.field("name", .string, .required)
			.create()
	}
	
	func revert(on database: Database) -> EventLoopFuture<Void> {
		return database.schema(Stop.schema)
			.delete()
	}
	
}
