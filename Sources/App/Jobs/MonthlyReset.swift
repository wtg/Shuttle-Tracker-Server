//
//  MonthlyReset.swift
//  Shuttle Tracker Server
//
//  Created by Mohammed Kalefa on 10/11/22.
//
// Calculate some basic statistics
// Reset boardbus count
// Delete entries older than 6 months

import Foundation
import Queues
import CoreGPX

/// A job that resets board buses usage every month.
struct MonthlyReset: AsyncScheduledJob {
	
	func run(context: QueueContext) async throws {
		let analyticsentries = try await AnalyticsEntry
			.query(on: context.application.db(.psql))
			.all()
		let calendar = Calendar.current
		for analyticsentry in analyticsentries {
			if (calendar.dateComponents([.month], from: analyticsentry.dateSent, to: Date()).month! >= 6){
				try await analyticsentry.delete(on: context.application.db(.psql))
				continue
			}
            analyticsentry.timesBoarded = 0
			try await analyticsentry.update(on: context.application.db(.psql))
		}
	}
	
}
