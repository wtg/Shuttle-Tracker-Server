//
//  AnnouncementController.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 1/10/24.
//

import FluentKit
import Vapor

/// A structure that registers routes for managing individual announcements.
/// - Remark: In the context of this structure, the term “route” refers to an HTTP route, not a shuttle route.
struct AnnouncementController<DecoderType>: RouteCollection where DecoderType: ContentDecoder {
	
	private let decoder: DecoderType
	
	/// Initializes a new announcement controller with the specified decoder.
    /// - Parameter decoder: An object that conforms to the `ContentDecoder` protocol, used for decoding the content of incoming requests.
	init(decoder: DecoderType) {
		self.decoder = decoder
	}
	
	/// Registers routes for accessing and deleting announcements by their ID.
    /// - Parameter routes: A builder object for registering routes.
	func boot(routes: any RoutesBuilder) throws {
		routes.group(":id") { (routes) in
			routes.get(use: self.read(_:))
			routes.delete(use: self.delete(_:))
		}
	}
	/// Retrieves an announcement by its ID.
    /// - Parameter request: A `Request` object encapsulating details about the incoming request, including the announcement ID.
    /// - Returns: The `Announcement` object requested.
    /// - Throws: An `Abort` error if the announcement is not found (404) or if the ID is not provided (400).
	private func read(_ request: Request) async throws -> Announcement {
		guard let id = request.parameters.get("id", as: UUID.self) else {
			throw Abort(.badRequest)
		}
		let announcement = try await Announcement
			.query(on: request.db(.psql))
			.filter(\.$id == id)
			.first()
		guard let announcement else {
			throw Abort(.notFound)
		}
		return announcement
	}

	/// Deletes an announcement by its ID after verifying the provided digital signature.
    /// - Parameter request: A `Request` object encapsulating details about the incoming request, including the announcement ID and a deletion request with a digital signature.
    /// - Returns: The UUID of the deleted announcement.
    /// - Throws: An `Abort` error if the ID is not provided (400), if signature verification fails (403), or if there are server issues during verification (500).
	private func delete(_ request: Request) async throws -> UUID {
		guard let id = request.parameters.get("id", as: UUID.self) else {
			throw Abort(.badRequest)
		}
		let deletionRequest = try request.content.decode(Announcement.DeletionRequest.self, using: self.decoder)
		guard let data = id.uuidString.data(using: .utf8) else {
			throw Abort(.internalServerError)
		}
		if try CryptographyUtilities.verify(signature: deletionRequest.signature, of: data) {
			try await Announcement
				.query(on: request.db(.psql))
				.filter(\.$id == id)
				.delete()
			return id
		} else {
			throw Abort(.forbidden)
		}
	}
	
}
