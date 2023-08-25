//
//  routes.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 9/21/20.
//

import Algorithms
import APNSCore
import Fluent
import UAParserSwift
import Vapor
import VaporAPNS

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

func routes(_ application: Application) throws {
	let decoder = JSONDecoder()
	decoder.dateDecodingStrategy = .iso8601
	
	// Fetch the user-agent string and redirect the user to the appropriate app distribution
	application.get { (request) -> Response in
		guard let agent = request.headers["User-Agent"].first else {
			return request.redirect(to: "/web")
		}
		let parser = UAParser(agent: agent)
		switch parser.os?.name?.lowercased() { // Switch on the user’s OS based on their user-agent string
		case "ios", "mac os":
			return request.redirect(to: "/swiftui")
		case "android":
			return request.redirect(to: "/android")
		default:
			return request.redirect(to: "/web")
		}
	}
	
	// Various redirects to certain distributions of the app
	application.get("swiftui") { (request) in
		return request.redirect(to: "https://apps.apple.com/us/app/shuttle-tracker/id1583503452")
	}
	application.get("swiftui", "beta") { (request) in
		return request.redirect(to: "https://testflight.apple.com/join/GsmZkfgd")
	}
	application.get("android") { (request) in
		return request.redirect(to: "https://play.google.com/store/apps/details?id=edu.rpi.shuttletracker")
	}
	application.get("android", "beta") { (request) in
		return request.redirect(to: "https://play.google.com/store/apps/details?id=edu.rpi.shuttletracker")
	}
	application.get("web") { (request) in
		return request.redirect(to: "https://web.shuttletracker.app")
	}
	application.get("web", "beta") { (request) in
		return request.redirect(to: "https://staging.web.shuttletracker.app")
	}
	application.get("beta") { (request) -> Response in
		guard let agent = request.headers["User-Agent"].first else {
			return request.redirect(to: "/web/beta")
		}
		let parser = UAParser(agent: agent)
		switch parser.os?.name?.lowercased() {
		case "ios", "mac os":
			return request.redirect(to: "/swiftui/beta")
		case "android":
			return request.redirect(to: "/android/beta")
		default:
			return request.redirect(to: "/web/beta")
		}
	}
	application.get("testflight") { (request) in
		return request.redirect(to: "/swiftui/beta")
	}
	
	// Return the current version number of the API
	application.get("version") { (_) in
		return Constants.apiVersion
	}
	
	application.get("schedule") { (request) in
		return request.redirect(to: "/schedule.json")
	}
	
	// Get the current milestones
	application.get("milestones") { (request) in
		return try await Milestone
			.query(on: request.db(.psql))
			.all()
	} 
	
	// Post a new milestone after verifying the request
	application.post("milestones") { (request) -> Milestone in
		let milestone = try request.content.decode(Milestone.self, using: decoder)
		guard let data = (milestone.name + milestone.extendedDescription + milestone.goals.description).data(using: .utf8) else {
			throw Abort(.internalServerError)
		}
		if try CryptographyUtilities.verify(signature: milestone.signature, of: data) {
			try await milestone.save(on: request.db(.psql))
			return milestone
		} else {
			throw Abort(.forbidden)
		}
	}
	
	// Increment a milestone with the given ID value
	application.patch("milestones", ":id") { (request) -> Milestone in
		guard let id = request.parameters.get("id", as: UUID.self) else { // Get the supplied ID value from the request URL
			throw Abort(.badRequest)
		}
		let milestone = try await Milestone // Fetch the first milestone from the database with the appropriate ID value
			.query(on: request.db(.psql))
			.filter(\.$id == id)
			.first()
		guard let milestone = milestone else {
			throw Abort(.notFound)
		}
		milestone.progress += 1 // Increment the milestone’s counter
		try await milestone.update(on: request.db(.psql)) // Update the milestone on the database
		return milestone
	}
	
	// Delete a given milestone after verifying the request
	application.delete("milestones", ":id") { (request) in
		guard let id = request.parameters.get("id", as: UUID.self) else {
			throw Abort(.badRequest)
		}
		let deletionRequest = try request.content.decode(Milestone.DeletionRequest.self, using: decoder)
		guard let data = id.uuidString.data(using: .utf8) else {
			throw Abort(.internalServerError)
		}
		if try CryptographyUtilities.verify(signature: deletionRequest.signature, of: data) {
			try await Milestone
				.query(on: request.db(.psql))
				.filter(\.$id == id)
				.delete()
			return id
		} else {
			throw Abort(.forbidden)
		}
	}
	
	// Get the current announcements
	application.get("announcements") { (request) in
		return try await Announcement
			.query(on: request.db(.psql))
			.all()
	}
	
	// Post a new announcement after verifying the request
	application.post("announcements") { (request) -> Announcement in
		let announcement = try request.content.decode(Announcement.self, using: decoder)
		guard let data = (announcement.subject + announcement.body).data(using: .utf8) else {
			throw Abort(.internalServerError)
		}
		if try CryptographyUtilities.verify(signature: announcement.signature, of: data) {
			try await announcement.save(on: request.db(.psql))
			
			// Send a push notification to all devices
			let devices = try await APNSDevice
				.query(on: request.db(.psql))
				.all()
			request.logger.log(level: .info, "[\(#fileID):\(#line) \(#function)] Sending a push notification to \(devices.count) devices…")
			try await withThrowingTaskGroup(of: Void.self) { (taskGroup) in
				let interruptionLevel: APNSAlertNotificationInterruptionLevel
				switch announcement.interruptionLevel {
				case .passive:
					interruptionLevel = .passive
				case .active:
					interruptionLevel = .active
				case .timeSensitive:
					interruptionLevel = .timeSensitive
				case .critical:
					interruptionLevel = .critical
				}
				let payload: Announcement.APNSPayload
				payload = try announcement.apnsPayload
				for device in devices {
					let deviceToken = device.token
					taskGroup.addTask {
						do {
							try await request.apns.client.sendAlertNotification(
								APNSAlertNotification(
									alert: APNSAlertNotificationContent(
										title: .raw("Announcement"),
										subtitle: .raw(announcement.subject),
										body: .raw(announcement.body),
										launchImage: nil
									),
									expiration: .none,
									priority: .immediately,
									topic: Constants.apnsTopic,
									payload: payload,
									sound: .default,
									mutableContent: 1,
									interruptionLevel: interruptionLevel,
									apnsID: announcement.id
								),
								deviceToken: deviceToken
							)
						} catch let error {
							request.logger.log(level: .error, "[\(#fileID):\(#line) \(#function)] Failed to send APNS notification: \(error)")
						}
					}
				}
			}
			
			return announcement
		} else {
			throw Abort(.forbidden)
		}
	}
	
	// Delete a given announcement after verifying the request
	application.delete("announcements", ":id") { (request) in
		guard let id = request.parameters.get("id", as: UUID.self) else {
			throw Abort(.badRequest)
		}
		let deletionRequest = try! request.content.decode(Announcement.DeletionRequest.self, using: decoder)
		guard let data = id.uuidString.data(using: .utf8) else {
			throw Abort(.internalServerError)
		}
		if try CryptographyUtilities.verify(signature: deletionRequest.signature, of: data) {
			try await Announcement
				.query(on: request.db(.psql))
				.filter(\.$id == id)
				.delete()
			return id
		} else {
			throw Abort(.forbidden)
		}
	}
	
	application.get("logs") { (request) in
		try await Log
			.query(on: request.db(.psql))
			.sort(\.$date)
			.all(\.$id)
	}
	
	application.post("logs") { (request) in
		let log = try request.content.decode(Log.self, using: decoder)
		log.id = UUID()
		try await log.save(on: request.db(.psql))
		return log.id
	}
	
	application.get("logs", ":id") { (request) in
		guard let id = request.parameters.get("id", as: UUID.self) else {
			throw Abort(.badRequest)
		}
		let retrievalRequest = try request.query.decode(Log.RetrievalRequest.self)
		guard let data = id.uuidString.data(using: .utf8) else {
			throw Abort(.internalServerError)
		}
		if try CryptographyUtilities.verify(signature: retrievalRequest.signature, of: data) {
			let log = try await Log
				.query(on: request.db(.psql))
				.filter(\.$id == id)
				.first()
			guard let log else {
				throw Abort(.notFound)
			}
			return log
		} else {
			throw Abort(.forbidden)
		}
	}
	
	application.delete("logs", ":id") { (request) in
		guard let id = request.parameters.get("id", as: UUID.self) else {
			throw Abort(.badRequest)
		}
		let deletionRequest = try request.content.decode(Log.DeletionRequest.self, using: decoder)
		guard let data = id.uuidString.data(using: .utf8) else {
			throw Abort(.internalServerError)
		}
		if try CryptographyUtilities.verify(signature: deletionRequest.signature, of: data) {
			try await Log
				.query(on: request.db(.psql))
				.filter(\.$id == id)
				.delete()
			return id.uuidString
		} else {
			throw Abort(.forbidden)
		}
	}
	
	// Return the contents of the data-feed
	application.get("datafeed") { (_) in
		return try String(contentsOf: Constants.datafeedURL)
	}
	
	// Attempt to fetch and to return the shuttle routes
	application.get("routes") { (request) in
		return try await Route
			.query(on: request.db(.sqlite))
			.all()
			.filter { (route) in
				return route.schedule.isActive
			}
	}
	
	// Attempt to fetch and to return the shuttle stops
	application.get("stops") { (request) in
		let stops = try await Stop
			.query(on: request.db(.sqlite))
			.all()
			.filter { (stop) in
				return stop.schedule.isActive
			}
			.uniqued()
		return Array(stops)
	}
	
	// TODO: Return something that’s actually useful
	application.get("stops", ":shortname") { (request) in
		return request.redirect(to: "/", redirectType: .temporary)
	}
	
	// Attempt to fetch and to return the shuttle buses
	application.get("buses") { (request) -> [Bus.Resolved] in
		let routes = try await Route
			.query(on: request.db(.sqlite))
			.all()
			.filter { (route) in
				return route.schedule.isActive
			}
		return try await Bus
			.query(on: request.db(.sqlite))
			.all()
			.compactMap { (bus) in
				return bus.resolved
			}
			.filter { (resolved) in
				return !routes.allSatisfy { (route) in
					return !route.checkIsOnRoute(location: resolved.location)
				}
			}
	}
	
	// Attempt to fetch and to return a list of all of the known bus ID numbers
	application.get("buses", "all") { (_) in
		return Buses.shared.allBusIDs
	}
	
	// Attempt to fetch and to return a bus with a given ID number
	application.get("buses", ":id") { (request) -> Bus.Location in
		guard let id = request.parameters.get("id", as: Int.self) else {
			throw Abort(.badRequest)
		}
		let buses = try await Bus
			.query(on: request.db(.sqlite))
			.filter(\.$id == id)
			.all()
		let locations = buses.flatMap { (bus) -> [Bus.Location] in
			return bus.locations
		}
		guard let location = locations.resolved else {
			throw Abort(.notFound)
		}
		return location
	}
	
	// Attempt to update a bus’s location
	application.patch("buses", ":id") { (request) -> Bus.Location? in
		guard let id = request.parameters.get("id", as: Int.self) else {
			throw Abort(.badRequest)
		}
		let location = try request.content.decode(Bus.Location.self, using: decoder)
		let routes = try await Route
			.query(on: request.db(.sqlite))
			.all()
			.filter { (route) in
				return route.schedule.isActive
			}
		let isOnRoute = !routes.allSatisfy { (route) in
			return !route.checkIsOnRoute(location: location)
		}
		guard isOnRoute else {
			throw Abort(.conflict)
		}
		let bus = try await Bus
			.query(on: request.db(.sqlite))
			.filter(\.$id == id)
			.first()
		guard let bus = bus else {
			throw Abort(.notFound)
		}
		bus.locations.merge(with: [location])
		bus.detectRoute(selectingFrom: routes)
		try await bus.update(on: request.db(.sqlite))
		return bus.locations.resolved
	}
	
	// Indicate that a user has boarded the bus with the given ID number
	application.put("buses", ":id", "board") { (request) -> Int? in
		guard let id = request.parameters.get("id", as: Int.self) else {
			throw Abort(.badRequest)
		}
		let bus = try await Bus
			.query(on: request.db(.sqlite))
			.filter(\.$id == id)
			.first()
		guard let bus = bus else {
			throw Abort(.notFound)
		}
		bus.congestion = (bus.congestion ?? 0) + 1
		try await bus.update(on: request.db(.sqlite))
		return bus.congestion
	}
	
	// Indicate that a user has left the bus with the given ID number
	application.put("buses", ":id", "leave") { (request) -> Int? in
		guard let id = request.parameters.get("id", as: Int.self) else {
			throw Abort(.badRequest)
		}
		let bus = try await Bus
			.query(on: request.db(.sqlite))
			.filter(\.$id == id)
			.first()
		guard let bus = bus else {
			throw Abort(.notFound)
		}
		bus.congestion = (bus.congestion ?? 1) - 1
		try await bus.update(on: request.db(.sqlite))
		return bus.congestion
	}
	
	// MARK: - Analytics
	
	application.get("analytics", "entries") { (request) in
		var query = AnalyticsEntry
			.query(on: request.db(.psql))
		if let userID: UUID = request.query["userid"] {
			query = query.filter(\.$userID == userID)
		} else if request.query[String.self, at: "userid"] != nil {
			throw Abort(.badRequest)
		}
		return try await query.all()
	}
	
	application.post("analytics", "entries") { (request) in
		let decoder = JSONDecoder()
		decoder.dateDecodingStrategy = .iso8601
		let analyticsEntry = try request.content.decode(AnalyticsEntry.self, using: decoder)
		try await analyticsEntry.save(on: request.db(.psql))
		return analyticsEntry
	}
	
	application.get("analytics", "entries", ":id") { (request) -> AnalyticsEntry in
		let entry = try await AnalyticsEntry.find(
			request.parameters.get("id"),
			on: request.db(.psql)
		)
		guard let entry else {
			throw Abort(.notFound)
		}
		return entry
	}
	
	application.get("analytics", "entries", "count") { (request) in
		return try await AnalyticsEntry
			.query(on: request.db(.psql))
			.count()
	}
	
	application.get("analytics", "userids") { (request) in
		return try await AnalyticsEntry
			.query(on: request.db(.psql))
			.unique()
			.all(\.$userID)
			.compactMap { return $0 } // Remove nil elements
	}
	
	application.get("analytics", "boardbus", "average") { (request) in
		let chunks = try await AnalyticsEntry
			.query(on: request.db(.psql))
			.filter(\.$userID != nil)
			.all()
			.chunked { return $0.userID == $1.userID }
		let sum = chunks.reduce(into: 0) { (partialResult, chunk) in
			partialResult += chunk
				.map { return $0.boardBusCount ?? 0 }
				.reduce(0, +)
		}
		return Double(sum) / Double(chunks.count)
	}
	
	// MARK: - Notifications
	
	application.post("notifications", "devices", ":token") { (request) in
		guard let token = request.parameters.get("token") else {
			throw Abort(.badRequest)
		}
		let existingDevice = try await APNSDevice
			.query(on: request.db(.psql))
			.filter(\.$token == token)
			.first()
		if let existingDevice {
			return existingDevice
		} else {
			let device = APNSDevice(token: token)
			try await device.create(on: request.db(.psql))
			return device
		}
	}
	
}
