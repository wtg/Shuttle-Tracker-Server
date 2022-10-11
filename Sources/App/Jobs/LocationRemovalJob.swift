//
//  LocationRemovalJob.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 9/22/20.
//

import Queues

/// A job that removes outdated location data.
struct LocationRemovalJob: AsyncScheduledJob {
	
	func run(context: QueueContext) async throws {
		let buses = try await Bus
			.query(on: context.application.db)
			.all()
		for bus in buses {
			bus.locations
				.filter { (location) in
					return location.type == .user && location.date.timeIntervalSinceNow < -30
				}
				.compactMap { (location) in
					return bus.locations.firstIndex(of: location)
				}
				.forEach { (index) in
					bus.locations.remove(at: index)
				}
			try await bus.update(on: context.application.db)
		}
	}
	
}
