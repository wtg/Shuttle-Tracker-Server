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

	/// Initializes a new milestones controller with the specified decoder.
    /// - Parameter decoder: An object that conforms to the `ContentDecoder` protocol, used for decoding the content of incoming requests.
	init(decoder: DecoderType) {
		self.decoder = decoder
	}

	/// Registers routes for creating and reading milestones along with registering a nested route collection for individual milestone management.
    /// - Parameter routes: A builder object for registering routes.
	func boot(routes: any RoutesBuilder) throws {
		routes.post(use: self.create(_:))
		routes.get(use: self.read(_:))
		try routes.register(collection: MilestoneController(decoder: self.decoder))
	}

	/// Creates a new milestone after verifying the digital signature.
    /// - Parameter request: A `Request` object encapsulating details about the incoming request.
    /// - Returns: The newly created `Milestone` object after it is saved to the database.
    /// - Throws: An `Abort` error if the digital signature verification fails (403) or if internal issues occur (500).
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
	/// Reads and returns all milestones from the database.
    /// - Parameter request: A `Request` object encapsulating details about the incoming request.
    /// - Returns: An array of `Milestone` objects.
	private func read(_ request: Request) async throws -> [Milestone] {
		return try await Milestone
			.query(on: request.db(.psql))
			.all()
	}
	
}
