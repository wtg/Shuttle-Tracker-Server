//
//  Milestone.swift
//  Shuttle Tracker Server
//
//  Jose Luchsinger - 2/8/22
//	

import Vapor
import Fluent

//	Defines the "Milestone" class, which tracks certain statistics and their progress towards a certain goal.
final class Announcement: Model, Content {
	
	/// Different types
	enum MilestoneType: String, Codable {
		
		case none = "none"
		
	}
	
	/// A representation of a signed request to delete a particular announcement from the server.
	struct DeletionRequest: Decodable {
		
		/// A cryptographic signature of the unique identifier of the announcement to be deleted.
		let signature: Data
		
	}
	
	static let schema = "announcements"
	
	@ID var id: UUID?
	
	/// The subject text of this announcement.
	@Field(key: "subject") var subject: String
	
	/// The body text of this announcement.
	@Field(key: "body") var body: String
	
	/// The date/time at which this announcement should begin being shown shown to users.
	@Field(key: "start") var start: Date
	
	/// The date/time at which this announcement should finish being shown to users.
	@Field(key: "end") var end: Date
	
	/// A cryptographic signature of the concatenation of the ``subject`` and ``body`` properties.
	@Field(key: "signature") var signature: Data
	
	/// The type of schedule that should be used by clients to display this announcement to users.
	@Enum(key: "schedule_type") var scheduleType: ScheduleType
	
	init() { }
	
}
