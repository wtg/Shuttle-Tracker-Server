//
//  LogsController.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 1/12/24.
//

import Vapor

/// A structure that registers routes for logs.
/// - Important: This structure registers routes on the index path of its provided routes builder, so make sure to enclose it in a named routes group to avoid path collisions.
/// - Remark: In the context of this structure, the term “route” refers to an HTTP route, not a shuttle route.
struct LogsController<DecoderType>: RouteCollection where DecoderType: ContentDecoder {
	
	private let decoder: DecoderType
	
	init(decoder: DecoderType) {
		self.decoder = decoder
	}
	
	func boot(routes: any RoutesBuilder) throws {
		routes.post(use: self.create(_:))
		routes.get(use: self.read(_:))
		try routes.register(collection: LogController(decoder: self.decoder))
	}
	
	private func create(_ request: Request) async throws -> UUID? {
		let log = try request.content.decode(Log.self, using: self.decoder)
		log.id = UUID()
		try await log.save(on: request.db(.psql))
		return log.id
	}
	
	private func read(_ request: Request) async throws -> [UUID] {
		return try await Log
			.query(on: request.db(.psql))
			.sort(\.$date)
			.all(\.$id)
	}
	
}
