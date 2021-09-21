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
//		let bundle = Bundle(path: "/app/.swift-bin/Shuttle Tracker Server_App.resources")!
//		let routeFileURL = bundle.url(forResource: "Route", withExtension: "gpx")!
//		let gpx = GPXParser(withURL: routeFileURL)!.parsedData()!
//		Route.query(on: context.application.db)
//			.all()
//			.mapEach { (route) in
//				route.delete(on: context.application.db)
//			}
//			.whenSuccess { (_) in
//				_ = Route(from: gpx.routes.first!).save(on: context.application.db)
//			}
//		Stop.query(on: context.application.db)
//			.all()
//			.mapEach { (stop) in
//				stop.delete(on: context.application.db)
//			}
//			.whenSuccess { (_) in
//				gpx.waypoints
//					.map { (gpxWaypoint) in
//						return Stop(from: gpxWaypoint)!
//					}
//					.forEach { (stop) in
//						_ = stop.save(on: context.application.db)
//					}
//			}
		return context.eventLoop.future()
	}
	
}
