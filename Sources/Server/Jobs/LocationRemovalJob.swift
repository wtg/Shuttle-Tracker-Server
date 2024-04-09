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
			.query(on: context.application.db(.sqlite))
			.all()
		let routes = try await Route // Failing to query route objects shouldn’t cause this method to fail entirely.
			.query(on: context.application.db(.sqlite))
			.all()
			.filter { (route) in
				return route.schedule.isActive
			}

		for bus in buses {
			if let busData = bus.resolved {
				for route in routes {
					let previousLocation = bus.locationHistory.first
					if (route.id == bus.routeID) {
						if (previousLocation != nil ) {
							bus.metersTraveledAlongRoute = route.getTotalDistanceTraveled(location: busData.location.coordinate, previousCoordinate: previousLocation!.location.coordinate) 
						}
						bus.locationHistory.append(busData)	
					}
					if (previousLocation != nil && previousLocation!.location.date.timeIntervalSinceNow < -360 && bus.locationHistory.count > 0) {
						bus.locationHistory.removeFirst()
					}
				}
			}
			bus.locations
				.filter { (location) in
					return location.type == .user && location.date.timeIntervalSinceNow < -30 // The time interval since now will be negative since the location’s timestamp will be in the past.
				}
				.compactMap { (location) in
					return bus.locations.firstIndex(of: location)
				}
				.forEach { (index) in
					bus.locations.remove(at: index) // It’s safe to remove locations here because we’re iterating over a filtered, mapped copy of the original array, not the original array itself.
				}
			// Detect the most recent route association, resetting it to nil if there’s no sufficiently recent location data
			bus.detectRoute(selectingFrom: routes)
			
			try await bus.update(on: context.application.db(.sqlite))
		}
	}
	
}
