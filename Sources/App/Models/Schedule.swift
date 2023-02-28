//
//  Schedule.swift
//  Shuttle Tracker Server
//
//  Created by Jason Jacobs on 2/17/2023.
//

import FluentKit
import Vapor

final class Schedule: Model, Content {
				
	struct Days: Codable {
				
		struct DaySchedule: Codable {
		
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
		
	enum EventType: Codable {
		
		case coldLaunch
		
		case boardBusTapped
		
		case leaveBusTapped
		
		case boardBusActivated(manual: Bool)
		
		case boardBusDeactivated(manual: Bool)
		
		case busSelectionCanceled
		
		case announcementsListOpened
		
		case announcementViewed(id: UUID)
		
		case permissionsSheetOpened
		
		case networkToastPermissionsTapped
		
		case colorBlindModeToggled(enabled: Bool)
		
		case debugModeToggled(enabled: Bool)
		
		case serverBaseURLChanged(url: URL)
		
		case locationAuthorizationStatusDidChange(authorizationStatus: LocationAuthorizationStatus)
		
		case locationAccuracyAuthorizationDidChange(accuracyAuthorization: LocationAccuracyAuthorization)
		
	}
	
	static let schema = "schedule"

	///
	///
	///
	@ID
	var id: UUID?
	
	/// name of the schedule (usually "semester 'year")
	@Field(key: "name")
	private(set) var name: String
	
	/// start date of when this schedule goes into use
	@Field(key: "start")
	private(set) var start: Date

	/// start date of when this schedule is no longer applicable
	@Field(key: "end")
	private(set) var end: Date
	
	/// contains the days of the week and the shuttle hours start and end times
	@Field(key: "content")
	private(set) var content: Days
	
}
