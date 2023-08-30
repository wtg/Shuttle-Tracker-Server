//
//  Annoucement.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 11/16/21.
//

import FluentKit
import Vapor

/// A representation of a time-limited announcement to display to users of the various clients.
final class Announcement: VersionedModel, Content {
	
	/// The various available schedule types.
	enum ScheduleType: String, Codable, DatabaseEnum {
		
		/// A schedule type that has neither a start date/time nor an end date/time.
		case none
		
		/// A schedule type that has a start date/time but not an end date/time.
		case startOnly
		
		/// A schedule type that has an end date/time but not a start date/time.
		case endOnly
		
		/// A schedule type that has both a start date/time and an end date/time.
		case startAndEnd
		
		static let name = #function
		
	}
	
	/// A representation of a signed request to delete a particular announcement from the server.
	struct DeletionRequest: Decodable {
		
		/// A cryptographic signature of the unique identifier of the announcement to delete.
		let signature: Data
		
	}
	
	enum InterruptionLevel: String, Codable, DatabaseEnum {
		
		case passive, active, timeSensitive, critical
		
		static var name = #function
		
	}
	
	struct APNSPayload: Encodable {
		
		let id: UUID
		
		let subject: String
		
		let body: String
		
		let start: Date
		
		let end: Date
		
		let scheduleType: ScheduleType
		
	}
	
	static let schema = "announcements"
	
	static var version: UInt = 2
	
	@ID
	var id: UUID?
	
	/// The subject text of this announcement.
	@Field(key: "subject")
	var subject: String
	
	/// The body text of this announcement.
	@Field(key: "body")
	var body: String
	
	/// The date/time at which this announcement should begin being shown shown to users.
	@Field(key: "start")
	var start: Date
	
	/// The date/time at which this announcement should finish being shown to users.
	@Field(key: "end")
	var end: Date
	
	/// The type of schedule that should be used by clients to display this announcement to users.
	@Enum(key: "schedule_type")
	var scheduleType: ScheduleType
	
	/// The degree to which notifications for this announcement interrupt users on client devices.
	@Enum(key: "interruption_level")
	var interruptionLevel: InterruptionLevel
	
	/// A cryptographic signature of the concatenation of the `subject` and `body` properties.
	@Field(key: "signature")
	var signature: Data
	
	var apnsPayload: APNSPayload {
		get throws {
			guard let id = self.id else {
				throw APNSPayloadError.noID
			}
			return APNSPayload(
				id: id,
				subject: self.subject,
				body: self.body,
				start: self.start,
				end: self.end,
				scheduleType: self.scheduleType
			)
		}
	}
	
	init() { }
	
}

fileprivate enum APNSPayloadError: LocalizedError {
	
	case noID
	
	var errorDescription: String? {
		get {
			switch self {
			case .noID:
				return "The announcement doesn’t have an ID."
			}
		}
	}
	
}
