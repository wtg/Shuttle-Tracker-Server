//
//  BusDownloadingJob.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 9/26/20.
//

import Queues

/// A job that downloads the latest system bus data.
struct BusDownloadingJob: AsyncScheduledJob {
	
	func run(context: QueueContext) async throws {
		var newBuses = try await Set<Bus>.download(application: context.application)
		let buses = try await Bus.query(on: context.application.db)
			.all()
		for bus in buses {
			if let newBus = newBuses.remove(bus) {
				bus.locations.merge(with: newBus.locations)
				try await bus.update(on: context.application.db)
			}
		}
		newBuses.save(on: context.application.db)
	}
	
}
