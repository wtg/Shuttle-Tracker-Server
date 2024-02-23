//
//  MilestonesController.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 1/10/24.
//

import Vapor

/// A structure that registers routes for milestones.
/// - Important: This structure registers routes on the index path of its provided routes builder, so make sure to enclose it in a named routes group to avoid path collisions.
/// - Remark: In the context of this structure, the term “route” refers to an HTTP route, not a shuttle route.
struct MilestonesController<DecoderType>: RouteCollection where DecoderType: ContentDecoder {
	
	private let decoder: DecoderType
	
	init(decoder: DecoderType) {
		self.decoder = decoder
	}
	
	func boot(routes: any RoutesBuilder) throws {
		routes.post(use: self.create(_:))
		routes.get(use: self.read(_:))
		try routes.register(collection: MilestoneController(decoder: self.decoder))
	}
	
	private func create(_ request: Request) async throws -> Milestone {
		let milestone = try request.content.decode(Milestone.self, using: self.decoder)
		guard let data = (milestone.name + milestone.extendedDescription + milestone.goals.description).data(using: .utf8) else {
			throw Abort(.internalServerError)
		}
		if try CryptographyUtilities.verify(signature: milestone.signature, of: data) {
			try await milestone.save(on: request.db(.psql))
			return milestone
		} else {
			throw Abort(.forbidden)
		}
	}
	
	private func read(_ request: Request) async throws -> [Milestone] {
		return try await Milestone
			.query(on: request.db(.psql))
			.all()
	}
	
}
