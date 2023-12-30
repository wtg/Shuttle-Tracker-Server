//
//  ScheduleInfo.swift
//  Shuttle Tracker
//
//  Created by Emily Ngo on 2/15/22.
//  Modified by Dylan Zhou on 10/10/23.
//

import Foundation

final class ScheduleInfo: Codable {
	
	struct Content: Codable {
		
		struct DaySchedule: Codable  {
			
			let start: String
			
			let end: String
			
		}
		
		let monday: DaySchedule
		
		let tuesday: DaySchedule
		
		let wednesday: DaySchedule
		
		let thursday: DaySchedule
		
		let friday: DaySchedule
		
		let saturday: DaySchedule
		
		let sunday: DaySchedule
		
	}
	
	let name: String
	
	let start: Date	
	
	let end: Date
	
	let content: Content
	
	init(name: String, start: Date, end: Date, content: Content) {
		self.name = name
		self.start = start
		self.end = end
		self.content = content
	}
	
}