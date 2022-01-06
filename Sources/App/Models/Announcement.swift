//
//  Annoucement.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 11/16/21.
//

import Vapor
import Fluent

final class Announcement: Model, Content {
	
	enum ScheduleType: String, Codable {
		
		case none = "none"
		
		case startOnly = "startOnly"
		
		case endOnly = "endOnly"
		
		case startAndEnd = "startAndEnd"
		
	}
	
	struct DeletionRequest: Decodable {
		
		let signature: Data
		
	}
	
	static let schema = "announcements"
	
	@ID var id: UUID?
	
	@Field(key: "subject") var subject: String
	
	@Field(key: "body") var body: String
	
	@Field(key: "start") var start: Date
	
	@Field(key: "end") var end: Date
	
	@Field(key: "signature") var signature: Data
	
	@Enum(key: "schedule_type") var scheduleType: ScheduleType
	
	init() { }
	
}
