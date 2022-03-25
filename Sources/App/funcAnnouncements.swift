//
//  routes.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 9/21/20.
//

import Vapor
import Fluent
import UAParserSwift

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

func funcAnnouncements(_ application: Application) throws {
	
	// Get the current announcements
	application.get("announcements") { (request) in
		return try await Announcement
			.query(on: request.db(.psql))
			.all()
	}
	
	// Post a new announcement after verifying it
	application.post("announcements") { (request) -> Announcement in 
		let decoder = JSONDecoder()
		decoder.dateDecodingStrategy = .iso8601
		let announcement = try request.content.decode(Announcement.self, using: decoder)
		guard let data = (announcement.subject + announcement.body).data(using: .utf8) else {
			throw Abort(.internalServerError)
		}
		if try CryptographyUtilities.verify(signature: announcement.signature, of: data) {
			try await announcement.save(on: request.db(.psql))
			return announcement
		} else {
			throw Abort(.forbidden)
		}
	}
	
	// Delete a given announcement after verifying it
	application.delete("announcements", ":id") { (request) -> String in
		guard let id = request.parameters.get("id", as: UUID.self) else {
			throw Abort(.badRequest)
		}
		let decoder = JSONDecoder()
		let deletionRequest = try request.content.decode(Announcement.DeletionRequest.self, using: decoder)
		guard let data = id.uuidString.data(using: .utf8) else {
			throw Abort(.internalServerError)
		}
		if try CryptographyUtilities.verify(signature: deletionRequest.signature, of: data) {
			try await Announcement
				.query(on: request.db(.psql))
				.filter(\.$id == id)
				.delete()
			return id.uuidString
		} else {
			throw Abort(.forbidden)
		}
	}
}
