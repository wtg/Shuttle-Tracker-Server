//
//  AnalyticsEntryController.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 1/12/24.
//

import Vapor

/// A structure that registers routes for managing individual analytics entries.
/// - Remark: In the context of this structure, the term “route” refers to an HTTP route, not a shuttle route.
struct AnalyticsEntryController: RouteCollection {
	
	func boot(routes: any RoutesBuilder) throws {
		routes.group(":id") { (routes) in
			routes.get(use: self.read(_:))
		}
	}
	
	private func read(_ request: Request) async throws -> AnalyticsEntry {

		// decode retrieval request 

		let retrievalRequest = try request.query.decode(AnalyticsEntry.RetrievalRequest.self)

		guard let idString = request.parameters.get("id"), let id = UUID(uuidString: idString) else { 
			throw Abort(.badRequest)
		}

		// cryptogrpahic verification 
		guard let data = id.uuidString.data(using: .utf8) else { 
			throw Abort(.internalServerError)
		}

		// crytographic signature 
		if try CryptographyUtilities.verify(signature: retrievalRequest.signature, of: data) { 
			let entry = try await AnalyticsEntry.find(
				id, 
				on: request.db(.psql)
			)
			guard let entry else {
				throw Abort(.notFound)
			}
			return entry 
		} else {
			throw Abort(.forbidden)
		}
	}
	
}

