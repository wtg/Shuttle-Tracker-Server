//
//  LogController.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 1/12/24.
//

import FluentKit
import Vapor

/// A structure that registers routes for managing individual logs.
/// - Remark: In the context of this structure, the term “route” refers to an HTTP route, not a shuttle route.
struct LogController<DecoderType>: RouteCollection where DecoderType: ContentDecoder {
	
	private let decoder: DecoderType
	
	init(decoder: DecoderType) {
		self.decoder = decoder
	}
	
	func boot(routes: any RoutesBuilder) throws {
		routes.group(":id") { (routes) in
			routes.get(use: self.read(_:))
			routes.delete(use: self.delete(_:))
		}
	}
	
	private func read(_ request: Request) async throws -> Log {
		guard let id = request.parameters.get("id", as: UUID.self) else {
			throw Abort(.badRequest)
		}
		let retrievalRequest = try request.query.decode(Log.RetrievalRequest.self)
		guard let data = id.uuidString.data(using: .utf8) else {
			throw Abort(.internalServerError)
		}
		if try CryptographyUtilities.verify(signature: retrievalRequest.signature, of: data) {
			let log = try await Log
				.query(on: request.db(.psql))
				.filter(\.$id == id)
				.first()
			guard let log else {
				throw Abort(.notFound)
			}
			return log
		} else {
			throw Abort(.forbidden)
		}
	}
	
	private func delete(_ request: Request) async throws -> String {
		guard let id = request.parameters.get("id", as: UUID.self) else {
			throw Abort(.badRequest)
		}
		let deletionRequest = try request.content.decode(Log.DeletionRequest.self, using: self.decoder)
		guard let data = id.uuidString.data(using: .utf8) else {
			throw Abort(.internalServerError)
		}
		if try CryptographyUtilities.verify(signature: deletionRequest.signature, of: data) {
			try await Log
				.query(on: request.db(.psql))
				.filter(\.$id == id)
				.delete()
			return id.uuidString
		} else {
			throw Abort(.forbidden)
		}
	}
	
}
