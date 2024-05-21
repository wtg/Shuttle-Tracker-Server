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
	
	/// Initializes a new log controller with the specified decoder.
    /// - Parameter decoder: An object that conforms to the `ContentDecoder` protocol, used for decoding the content of incoming requests.
	init(decoder: DecoderType) {
		self.decoder = decoder
	}
	
	/// Registers routes for accessing and deleting logs by their ID.
    /// - Parameter routes: A builder object for registering routes.
	func boot(routes: any RoutesBuilder) throws {
		routes.group(":id") { (routes) in
			routes.get(use: self.read(_:))
			routes.delete(use: self.delete(_:))
		}
	}

	/// Retrieves a log by its ID after verifying the digital signature.
    /// - Parameter request: A `Request` object encapsulating details about the incoming request, including the log ID.
    /// - Returns: The `Log` object requested.
    /// - Throws: An `Abort` error if the log is not found (404), the ID is not provided (400), or the digital signature verification fails (403).
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
	/// Deletes a log by its ID after verifying the digital signature.
    /// - Parameter request: A `Request` object encapsulating details about the incoming request, including the log ID and a deletion request with a digital signature.
    /// - Returns: The UUID of the deleted log as a string.
    /// - Throws: An `Abort` error if the ID is not provided (400), if signature verification fails (403), or if there are server issues during verification (500).
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
