//
//  BusDownloadingJob.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 9/26/20.
//

import Queues

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// A job that downloads the latest system bus data.
struct BusDownloadingJob: AsyncScheduledJob {
	
	func run(context: QueueContext) async throws {
		let newBuses = try await Downloaders.getBuses(on: context.application)
		var allNewBuses: Set<Bus> = []
		for newBus in newBuses {
			allNewBuses.insert(newBus)
		}
		let activeRoutes = try await Route
			.query(on: context.application.db)
			.all()
			.filter { (route) in
				return route.schedule.isActive
			}
		let buses = try await Bus
			.query(on: context.application.db)
			.all()
		for bus in buses {
			if let newBus = allNewBuses.remove(bus) {
				bus.locations.merge(with: newBus.locations)
				//bus.detectRoute(selectingFrom: activeRoutes)
				//bus.detectDistanceTraveled(selectingFrom: activeRoutes)
				try await bus.update(on: context.application.db)
			}
		}
		try await allNewBuses.save(on: context.application.db)
	}
	
}
