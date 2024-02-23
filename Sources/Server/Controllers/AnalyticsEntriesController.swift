//
//  AnalyticsEntriesController.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 1/12/24.
//

import FluentKit
import Vapor

/// A structure that registers routes for analytics entries.
/// - Important: This structure registers routes on the index path of its provided routes builder, so make sure to enclose it in a named routes group to avoid path collisions.
/// - Remark: In the context of this structure, the term “route” refers to an HTTP route, not a shuttle route.
struct AnalyticsEntriesController<DecoderType>: RouteCollection where DecoderType: ContentDecoder {
	
	private let decoder: DecoderType
	
	init(decoder: DecoderType) {
		self.decoder = decoder
	}
	
	func boot(routes: any RoutesBuilder) throws {
		routes.post(use: self.create(_:))
		routes.get(use: self.read(_:))
		routes.get("count", use: self.count(_:))
		try routes.register(collection: AnalyticsEntryController())
	}
	
	private func create(_ request: Request) async throws -> AnalyticsEntry {
		let analyticsEntry = try request.content.decode(AnalyticsEntry.self, using: self.decoder)
		try await analyticsEntry.save(on: request.db(.psql))
		return analyticsEntry
	}
	
	private func read(_ request: Request) async throws -> [AnalyticsEntry] {
		var query = AnalyticsEntry
			.query(on: request.db(.psql))
		if let userID: UUID = request.query["userid"] {
			query = query.filter(\.$userID == userID)
		} else if request.query[String.self, at: "userid"] != nil {
			throw Abort(.badRequest)
		}
		return try await query.all()
	}
	
	private func count(_ request: Request) async throws -> Int {
		return try await AnalyticsEntry
			.query(on: request.db(.psql))
			.count()
	}
	
}
