//
//  GPXImportingJob.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 10/20/20.
//

import Foundation
import Queues
import CoreGPX

/// A job that imports route and stop data from a local GPX file.
struct GPXImportingJob: ScheduledJob {
	
	func run(context: QueueContext) -> EventLoopFuture<Void> {
		let routeFileURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
			.appendingPathComponent("Public", isDirectory: true)
			.appendingPathComponent("route.gpx", isDirectory: false)
		if let gpx = GPXParser(withURL: routeFileURL)?.parsedData() {
			Route.query(on: context.application.db)
				.all()
				.mapEach { (route) in
					route.delete(on: context.application.db)
				}
				.whenSuccess { (_) in
					_ = Route(from: gpx.tracks.first!.segments.first!).save(on: context.application.db)
				}
			Stop.query(on: context.application.db)
				.all()
				.mapEach { (stop) in
					stop.delete(on: context.application.db)
				}
				.whenSuccess { (_) in
					gpx.waypoints
						.map { (gpxWaypoint) in
							return Stop(from: gpxWaypoint)!
						}
						.forEach { (stop) in
							_ = stop.save(on: context.application.db)
						}
				}
		}
		return context.eventLoop.future()
	}
	
}
