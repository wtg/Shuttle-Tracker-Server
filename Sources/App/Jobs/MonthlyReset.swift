//
//  MonthlyReset.swift
//  Shuttle Tracker Server
//
//  Created by Mohammed Kalefa on 10/11/22.
//

import Foundation
import Queues
import CoreGPX

/// A job that resets board buses usage every month.
struct MonthlyReset: AsyncScheduledJob {
	
	func run(context: QueueContext) async throws {
		let analyticsentries = try await AnalyticsEntry
			.query(on: context.application.db)
			.all()
		for analyticsentry in analyticsentries {
            analyticsentry.timesBoarded = 0
			try await analyticsentry.update(on: context.application.db)
		}
	}
	
}
