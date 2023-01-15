//
//  GPXImportingJob.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 10/20/20.
//

import Foundation
import JSONParser
import Queues
import CoreGPX

/// A job that imports route and stop data from a local GPX file.
struct GPXImportingJob: AsyncScheduledJob {
	
	func run(context: QueueContext) async throws {
		let routesInfoData = try Data(
			contentsOf: URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
				.appendingPathComponent("Public", isDirectory: true)
				.appendingPathComponent("routes.json", isDirectory: false)
		)
		let routesInfoParser = routesInfoData.dictionaryParser!
		let routesDirectoryURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
			.appendingPathComponent("Public", isDirectory: true)
			.appendingPathComponent("routes-data", isDirectory: true)
		let routesFileURLs = try FileManager.default.contentsOfDirectory(at: routesDirectoryURL, includingPropertiesForKeys: nil)
			.filter { (url) in
				return url.pathExtension == "gpx"
			}
		let routes = try await Route
			.query(on: context.application.db)
			.all()
		for route in routes {
			try await route.delete(on: context.application.db)
		}
		let stops = try await Stop
			.query(on: context.application.db)
			.all()
		for stop in stops {
			try await stop.delete(on: context.application.db)
		}
		for routesFileURL in routesFileURLs {
			let decoder = JSONDecoder()
			decoder.dateDecodingStrategy = .iso8601
			let schedule: MapSchedule
			do {
				let routesInfoData = try routesInfoParser.get(dataAt: routesFileURL.lastPathComponent, asCollection: [String: Any].self)
				schedule = try decoder.decode(MapSchedule.self, from: routesInfoData)
			} catch let error {
				errorPrint("Couldn’t decode map schedule for GPX file “\(routesFileURL.lastPathComponent)”: \(error)")
				schedule = .always
			}
			let parser = GPXParser(withURL: routesFileURL)
			guard let gpx = parser?.parsedData() else {
				errorPrint("Couldn’t parse GPX file “\(routesFileURL.lastPathComponent)”")
				continue
			}
			for gpxRoute in gpx.routes {
				do {
					try await Route(from: gpxRoute, schedule: schedule)
						.save(on: context.application.db)
					for gpxWaypoint in gpx.waypoints {
						try await Stop(from: gpxWaypoint, withSchedule: schedule)!
							.save(on: context.application.db)
					}
				} catch let error {
					errorPrint("Couldn’t import GPX route from file “\(routesFileURL.lastPathComponent)”: \(error)")
				}
			}
		}
	}
	
}
