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
	
	/// Initializes a new logs controller with the specified decoder.
    /// - Parameter decoder: An object that conforms to the `ContentDecoder` protocol, used for decoding the content of incoming requests.
	init(decoder: DecoderType) {
		self.decoder = decoder
	}
	
	/// Registers routes for creating and reading logs along with registering a nested route collection for individual log management.
    /// - Parameter routes: A builder object for registering routes.
	func boot(routes: any RoutesBuilder) throws {
		routes.post(use: self.create(_:))
		routes.get(use: self.read(_:))
		try routes.register(collection: LogController(decoder: self.decoder))
	}
	
	/// Creates a new log entry from the request's content, assigns a unique ID, and saves it to the database.
    /// - Parameter request: A `Request` object encapsulating details about the incoming request.
    /// - Returns: The UUID of the newly created log entry.
    /// - Throws: An error if the log data cannot be decoded or saved.
	private func create(_ request: Request) async throws -> UUID? {
		let log = try request.content.decode(Log.self, using: self.decoder)
		log.id = UUID()
		try await log.save(on: request.db(.psql))
		return log.id
	}
	/// Retrieves all log entry IDs, sorted by the date they were created.
    /// - Parameter request: A `Request` object encapsulating details about the incoming request.
    /// - Returns: An array of UUIDs representing the IDs of all log entries.
    /// - Throws: An error if there is a failure in retrieving the data from the database.
    
	private func read(_ request: Request) async throws -> [UUID] {
		return try await Log
			.query(on: request.db(.psql))
			.sort(\.$date)
			.all(\.$id)
	}
	
}
