//
//  Day.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 5/13/22.
//

import Foundation

/// A day of the week.
enum Day: String, Codable, CaseIterable {
	
	case monday, tuesday, wednesday, thursday, friday, saturday, sunday
	
	/// Creates a representation of the day of the week that’s associated with a given date.
	///
	/// This initializer fails and evaluates to `nil` when the day of the week that’s associated with the given date can’t be computed.
	/// - Parameter date: The date to consider.
	init?(from date: Date) {
		var calendar = Calendar(identifier: .gregorian)
		calendar.timeZone = TimeZone(identifier: "America/New_York")!
		let components = calendar.dateComponents([.weekday], from: date)
		guard let weekday = components.weekday else {
			return nil
		}
		switch weekday {
		case 1:
			self = .sunday
		case 2:
			self = .monday
		case 3:
			self = .tuesday
		case 4:
			self = .wednesday
		case 5:
			self = .thursday
		case 6:
			self = .friday
		case 7:
			self = .saturday
		default:
			return nil
		}
	}
	
}

extension Set where Element == Day {
	
	static let all = Set(Day.allCases)
	
}
