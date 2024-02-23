//
//  AnalyticsController.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 1/12/24.
//

import FluentKit
import Vapor

/// A structure that registers routes for analytics.
/// - Remark: In the context of this structure, the term “route” refers to an HTTP route, not a shuttle route.
struct AnalyticsController<DecoderType>: RouteCollection where DecoderType: ContentDecoder {
	
	private let decoder: DecoderType
	
	init(decoder: DecoderType) {
		self.decoder = decoder
	}
	
	func boot(routes: any RoutesBuilder) throws {
		routes.get("userids", use: self.userIDs(_:))
		routes.get("boardbus", "average", use: self.boardBusAverage(_:))
		try routes.register(collection: AnalyticsEntriesController(decoder: self.decoder), on: "entries")
	}
	
	private func userIDs(_ request: Request) async throws -> [UUID] {
		return try await AnalyticsEntry
			.query(on: request.db(.psql))
			.unique()
			.all(\.$userID)
			.compactMap { return $0 } // Remove nil elements
	}
	
	private func boardBusAverage(_ request: Request) async throws -> Double {
		let chunks = try await AnalyticsEntry
			.query(on: request.db(.psql))
			.filter(\.$userID != nil)
			.all()
			.chunked { return $0.userID == $1.userID }
		let sum = chunks.reduce(into: 0) { (partialResult, chunk) in
			partialResult += chunk
				.map { return $0.boardBusCount ?? 0 }
				.reduce(0, +)
		}
		return Double(sum) / Double(chunks.count)
	}
	
}
