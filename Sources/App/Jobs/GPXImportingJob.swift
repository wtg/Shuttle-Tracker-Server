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
struct GPXImportingJob: AsyncScheduledJob {
	
	func run(context: QueueContext) async throws {
		let routeFileURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
			.appendingPathComponent("Public", isDirectory: true)
			.appendingPathComponent("route.gpx", isDirectory: false)
		let parser = GPXParser(withURL: routeFileURL)
		guard let gpx = parser?.parsedData() else {
			return
		}
		let routes = try await Route
			.query(on: context.application.db)
			.all()
		for route in routes {
			try await route.delete(on: context.application.db)
		}
		try await Route(from: gpx.tracks.first!.segments.first!)
			.save(on: context.application.db)
		let stops = try await Stop
			.query(on: context.application.db)
			.all()
		for stop in stops {
			try await stop.delete(on: context.application.db)
		}
		let newStops = gpx.waypoints.map { (gpxWaypoint) in
			return Stop(from: gpxWaypoint)!
		}
		for newStop in newStops {
			try await newStop.save(on: context.application.db)
		}
	}
	
}
