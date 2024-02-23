//
//  DateIntervalProtocol.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 8/25/23.
//

import Foundation

protocol DateIntervalProtocol {
	
	var start: Date { get }
	
	var end: Date { get }
	
	func contains(_ date: Date) -> Bool
	
}

extension DateInterval: DateIntervalProtocol { }

extension DateUtilities {
	
	/// Creates a date interval with an opaque concrete implementation.
	///
	/// The standard `DateInterval` structure from `Foundation` is partially broken on Linux and Windows, so this method will automatically select an appropriate concrete implementation that works properly on the target platform.
	/// - Parameters:
	///   - start: The start date.
	///   - end: The end date.
	/// - Returns: A value of some opaque type that conforms to ``DateIntervalProtocol``.
	static func createInterval(from start: Date, to end: Date) -> some DateIntervalProtocol {
		#if os(Linux) || os(Windows)
		return CompatibilityDateInterval(start: start, end: end)
		#else // os(Linux) || os(Windows)
		return DateInterval(start: start, end: end)
		#endif
	}
	
}

#if os(Linux) || os(Windows)
fileprivate struct CompatibilityDateInterval: DateIntervalProtocol {
	
	let start: Date
	
	let end: Date
	
	init(start: Date, end: Date) {
		self.start = start
		self.end = end
	}
	
	func contains(_ date: Date) -> Bool {
		return date >= self.start && date <= self.end
	}
	
}
#endif // os(Linux) || os(Windows)
