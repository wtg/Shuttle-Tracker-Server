//
//  MilestoneController.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 1/10/24.
//

import FluentKit
import Vapor

/// A structure that registers routes for managing individual milestones.
/// - Remark: In the context of this structure, the term “route” refers to an HTTP route, not a shuttle route.
struct MilestoneController<DecoderType>: RouteCollection where DecoderType: ContentDecoder {
	
	private let decoder: DecoderType
	
	init(decoder: DecoderType) {
		self.decoder = decoder
	}
	
	func boot(routes: any RoutesBuilder) throws {
		routes.group(":id") { (routes) in
			routes.get(use: self.read(_:))
			routes.patch(use: self.update(_:))
			routes.delete(use: self.delete(_:))
		}
	}
	
	private func read(_ request: Request) async throws -> Milestone {
		guard let id = request.parameters.get("id", as: UUID.self) else {
			throw Abort(.badRequest)
		}
		let milestone = try await Milestone
			.query(on: request.db(.psql))
			.filter(\.$id == id)
			.first()
		guard let milestone else {
			throw Abort(.notFound)
		}
		return milestone
	}
	
	private func update(_ request: Request) async throws -> Milestone {
		guard let id = request.parameters.get("id", as: UUID.self) else {
			throw Abort(.badRequest)
		}
		let milestone = try await Milestone
			.query(on: request.db(.psql))
			.filter(\.$id == id)
			.first()
		guard let milestone else {
			throw Abort(.notFound)
		}
		milestone.progress += 1 // Increment the milestone’s counter
		try await milestone.update(on: request.db(.psql))
		return milestone
	}
	
	private func delete(_ request: Request) async throws -> UUID {
		guard let id = request.parameters.get("id", as: UUID.self) else {
			throw Abort(.badRequest)
		}
		let deletionRequest = try request.content.decode(Milestone.DeletionRequest.self, using: self.decoder)
		guard let data = id.uuidString.data(using: .utf8) else {
			throw Abort(.internalServerError)
		}
		if try CryptographyUtilities.verify(signature: deletionRequest.signature, of: data) {
			try await Milestone
				.query(on: request.db(.psql))
				.filter(\.$id == id)
				.delete()
			return id
		} else {
			throw Abort(.forbidden)
		}
	}
	
}
