//
//  CreateRoutes.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 10/20/20.
//

import Fluent

struct CreateRoutes: Migration {
	
	func prepare(on database: Database) -> EventLoopFuture<Void> {
		return database.schema(Route.schema)
			.id()
			.field("coordinates", .array(of: .custom(Coordinate.self)), .required)
			.field("stop_ids", .array(of: .int), .required)
			.field("internal_color", .string)
			.create()
	}
	
	func revert(on database: Database) -> EventLoopFuture<Void> {
		return database.schema(Route.schema)
			.delete()
	}
	
}
