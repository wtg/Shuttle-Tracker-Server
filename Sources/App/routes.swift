//
//  routes.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 9/21/20.
//

import Vapor
import Fluent
import UAParserSwift

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

func routes(_ application: Application) throws {
	application.get { (request) -> Response in
		guard let agent = request.headers["User-Agent"].first else {
			return request.redirect(to: "/web")
		}
		let parser = UAParser(agent: agent)
		switch parser.os?.name?.lowercased() {
		case "ios", "mac os":
			return request.redirect(to: "/swiftui")
		case "android":
			return request.redirect(to: "/android")
		default:
			return request.redirect(to: "/web")
		}
	}
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
	application.get("version") { (_) in
		return Constants.apiVersion
	}
	application.get("schedule") { (request) in
		return request.redirect(to: "/schedule.json")
	}
	application.get("announcements") { (request) in
		return try await Announcement
			.query(on: request.db(.psql))
			.all()
	}
	application.post("announcements") { (request) -> Announcement in
		let decoder = JSONDecoder()
		decoder.dateDecodingStrategy = .iso8601
		let announcement = try request.content.decode(Announcement.self, using: decoder)
		guard let data = (announcement.subject + announcement.body).data(using: .utf8) else {
			throw Abort(.internalServerError)
		}
		if try CryptographyUtilities.verify(signature: announcement.signature, of: data) {
			try await announcement.save(on: request.db(.psql))
			return announcement
		} else {
			throw Abort(.forbidden)
		}
	}
	application.delete("announcements", ":id") { (request) -> String in
		guard let id = request.parameters.get("id", as: UUID.self) else {
			throw Abort(.badRequest)
		}
		let decoder = JSONDecoder()
		let deletionRequest = try request.content.decode(Announcement.DeletionRequest.self, using: decoder)
		guard let data = id.uuidString.data(using: .utf8) else {
			throw Abort(.internalServerError)
		}
		if try CryptographyUtilities.verify(signature: deletionRequest.signature, of: data) {
			try await Announcement
				.query(on: request.db(.psql))
				.filter(\.$id == id)
				.delete()
			return id.uuidString
		} else {
			throw Abort(.forbidden)
		}
	}
	application.get("datafeed") { (_) in
		return try String(contentsOf: Constants.datafeedURL)
	}
	application.get("routes") { (request) in
		return try await Route
			.query(on: request.db)
			.all()
	}
	application.get("stops") { (request) in
		return try await Stop
			.query(on: request.db)
			.all()
	}
	application.get("stops", ":shortname") { (request) in
		return request.redirect(to: "/", type: .temporary)
	}
	application.get("buses") { (request) in
		return try await Bus
			.query(on: request.db)
			.all()
			.compactMap { (bus) in
				return bus.resolved
			}
	}
	application.get("buses", "all") { (_) in
		return Buses.shared.allBusIDs
	}
	application.get("buses", ":id") { (request) -> Bus.Location in
		guard let id = request.parameters.get("id", as: Int.self) else {
			throw Abort(.badRequest)
		}
		let buses = try await Bus
			.query(on: request.db)
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
	application.patch("buses", ":id") { (request) -> Bus.Location? in
		guard let id = request.parameters.get("id", as: Int.self) else {
			throw Abort(.badRequest)
		}
		let location = try request.content.decode(Bus.Location.self)
		
		// TODO: Handle multiple routes
		let isValid = try await Route
			.query(on: request.db)
			.first()?
			.checkIfValid(location: location) ?? false
		
		guard isValid else {
			throw Abort(.conflict)
		}
		let bus = try await Bus
			.query(on: request.db)
			.filter(\.$id == id)
			.first()
		guard let bus = bus else {
			throw Abort(.notFound)
		}
		bus.locations.merge(with: [location])
		try await bus.update(on: request.db)
		return bus.locations.resolved
	}
	application.put("buses", ":id", "board") { (request) -> Int? in
		guard let id = request.parameters.get("id", as: Int.self) else {
			throw Abort(.badRequest)
		}
		let bus = try await Bus
			.query(on: request.db)
			.filter(\.$id == id)
			.first()
		guard let bus = bus else {
			throw Abort(.notFound)
		}
		bus.congestion = (bus.congestion ?? 0) + 1
		try await bus.update(on: request.db)
		return bus.congestion
	}
	application.put("buses", ":id", "leave") { (request) -> Int? in
		guard let id = request.parameters.get("id", as: Int.self) else {
			throw Abort(.badRequest)
		}
		let bus = try await Bus
			.query(on: request.db)
			.filter(\.$id == id)
			.first()
		guard let bus = bus else {
			throw Abort(.notFound)
		}
		bus.congestion = (bus.congestion ?? 1) - 1
		try await bus.update(on: request.db)
		return bus.congestion
	}
}
