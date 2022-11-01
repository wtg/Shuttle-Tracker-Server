//
//  Log.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 10/27/22.
//

import Fluent
import Vapor

/// A representation of a debug log that’s uploaded by a client.
final class Log: Model, Content {
	
	/// A representation of a signed request to retrieve a particular log from the server.
	typealias RetrievalRequest = OperationRequest
	
	/// A representation of a signed request to delete a particular log from the server.
	typealias DeletionRequest = OperationRequest
	
	/// A representation of a signed request to operate on a particular log from the server.
	struct OperationRequest: Decodable {
		
		/// A cryptographic signature of the unique identifier of the log on which to operate.
		let signature: Data
		
	}
	
	static let schema = "logs"
	
	@ID var id: UUID?
	
	/// The content of this log.
	@Field(key: "content") private(set) var content: String
	
	/// The timestamp of this log.
	@Field(key: "date") var date: Date
	
}
