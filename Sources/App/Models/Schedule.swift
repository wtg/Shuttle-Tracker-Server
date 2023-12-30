//
//  Schedule.swift
//  Shuttle Tracker Server
//
//  Created by Dylan Zhou on 10/06/23.
//

import CoreGPX
import FluentKit
import JSONParser
import Vapor

/// A representation of a schedule.
final class Schedule: Model, Content {
	
	static let schema = "schedules"
	
	@ID
	var id: UUID?
	
	/// The human-readable name of this stop.
	@Field(key: "name")
	var name: String

	/// The start date of the schedule
	@Field(key: "start")
    var startDate: Date

	/// The end date of the schedule
    @Field(key: "end")
    var endDate: Date

	/// The actual schedule of when busses run	
    @Field(key: "content")
    var content: ScheduleInfo.Content

	init() { }
	
    init?(from infoSchedule: ScheduleInfo) {
		self.name = infoSchedule.name
        self.startDate = infoSchedule.start
        self.endDate = infoSchedule.end
        self.content = infoSchedule.content
	}

	var isActive: Bool {
		get {
			if endDate > Date.now {
				return true
			} else {
				return false
			}
		}
	}
	

}
