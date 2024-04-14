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
	
	/// Initializes a new milestone controller with the specified decoder.
    /// - Parameter decoder: An object that conforms to the `ContentDecoder` protocol, used for decoding the content of incoming requests.
    
	init(decoder: DecoderType) {
		self.decoder = decoder
	}
	
	/// Registers routes for accessing, updating, and deleting milestones by their ID.
    /// - Parameter routes: A builder object for registering routes.
    
	func boot(routes: any RoutesBuilder) throws {
		routes.group(":id") { (routes) in
			routes.get(use: self.read(_:))
			routes.patch(use: self.update(_:))
			routes.delete(use: self.delete(_:))
		}
	}

	/// Retrieves a milestone by its ID.
    /// - Parameter request: A `Request` object encapsulating details about the incoming request, including the milestone ID.
    /// - Returns: The `Milestone` object requested.
    /// - Throws: An `Abort` error if the milestone is not found (404) or the ID is not provided (400).
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
	/// Updates a milestone by incrementing its progress counter.
    /// - Parameter request: A `Request` object encapsulating details about the incoming request, including the milestone ID.
    /// - Returns: The updated `Milestone` object.
    /// - Throws: An `Abort` error if the milestone is not found (404) or the ID is not provided (400).
   
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
	
	/// Deletes a milestone by its ID after verifying the digital signature.
    /// - Parameter request: A `Request` object encapsulating details about the incoming request, including the milestone ID and a deletion request with a digital signature.
    /// - Returns: The UUID of the deleted milestone.
    /// - Throws: An `Abort` error if the ID is not provided (400), if signature verification fails (403), or if there are server issues during verification (500).
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
