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
		let buses = try await Bus.query(on: context.application.db)
			.all()
		for bus in buses {
			let oldLocations = bus.locations.filter { (location) in
				return location.date.timeIntervalSinceNow < -300
			}
			let oldLocationsIndices = oldLocations.compactMap { (location) in
				return bus.locations.firstIndex(of: location)
			}
			oldLocationsIndices.forEach { (index) in
				bus.locations.remove(at: index)
			}
			try await bus.update(on: context.application.db)
		}
	}
	
}
