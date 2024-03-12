//
//  MapSchedule.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 5/2/22.
//

import Foundation

/// A representation of a schedule that determines when a particular map object is active.
struct MapSchedule: Codable {
	
	private enum CodingKeys: CodingKey {
		
		case start, end, days, specialIntervals, doInvertSpecialIntervals
		
		enum SpecialInterval: CodingKey {
			
			case start, end
			
		}
		
	}
	
	static let always = MapSchedule(
		interval: DateUtilities.createInterval(
			from: .distantPast,
			to: .distantFuture
		),
		days: .all,
		specialIntervals: []
	)
	
	/// The normal date interval during which this schedule is active.
	let interval: any DateIntervalProtocol
	
	/// The days of the week on which this schedule is active within the bounds of its normal date interval.
	let days: Set<Day>
	
	/// Special date intervals during which this schedule is active outside of its normal activity periods.
	let specialIntervals: [any DateIntervalProtocol]
	
	/// Whether to invert the semantics of the special-interval array.
	let doInvertSpecialIntervals: Bool
	
	/// Whether this schedule is currently active based on the current date.
	var isActive: Bool {
		get {
			let isInSpecialInterval = self.specialIntervals.contains { (specialInterval) in
				return specialInterval.contains(.now)
			}
			if isInSpecialInterval {
				if self.doInvertSpecialIntervals {
					return false
				} else {
					return true
				}
			} else {
				if self.interval.contains(.now) {
					if let day = Day(from: .now) {
						return self.days.contains(day)
					} else {
						return true
					}
				} else {
					return false
				}
			}
		}
	}
	
	init(interval: any DateIntervalProtocol, days: Set<Day>, specialIntervals: [any DateIntervalProtocol], doInvertSpecialIntervals: Bool = false) {
		self.interval = interval
		self.days = days
		self.specialIntervals = specialIntervals
		self.doInvertSpecialIntervals = doInvertSpecialIntervals
	}
	
	init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.interval = DateUtilities.createInterval(
			from: try container.decodeIfPresent(Date.self, forKey: .start) ?? .distantPast,
			to: try container.decodeIfPresent(Date.self, forKey: .end) ?? .distantFuture
		)
		self.days = try container.decode(Set<Day>.self, forKey: .days)
		var specialIntervalsContainer = try container.nestedUnkeyedContainer(forKey: .specialIntervals)
		var specialIntervals: [any DateIntervalProtocol] = []
		while !specialIntervalsContainer.isAtEnd {
			let specialIntervalContainer = try specialIntervalsContainer.nestedContainer(keyedBy: CodingKeys.SpecialInterval.self)
			let specialInterval = DateUtilities.createInterval(
				from: try specialIntervalContainer.decode(Date.self, forKey: .start),
				to: try specialIntervalContainer.decode(Date.self, forKey: .end)
			)
			specialIntervals.append(specialInterval)
		}
		self.specialIntervals = specialIntervals
		self.doInvertSpecialIntervals = try container.decode(Bool.self, forKey: .doInvertSpecialIntervals)
	}
	
	func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(self.interval.start, forKey: .start)
		try container.encode(self.interval.end, forKey: .end)
		try container.encode(self.days, forKey: .days)
		var specialIntervalsContainer = container.nestedUnkeyedContainer(forKey: .specialIntervals)
		for specialInterval in self.specialIntervals {
			var specialIntervalContainer = specialIntervalsContainer.nestedContainer(keyedBy: CodingKeys.SpecialInterval.self)
			try specialIntervalContainer.encode(specialInterval.start, forKey: .start)
			try specialIntervalContainer.encode(specialInterval.end, forKey: .end)
		}
		try container.encode(self.doInvertSpecialIntervals, forKey: .doInvertSpecialIntervals)
	}
	
}
