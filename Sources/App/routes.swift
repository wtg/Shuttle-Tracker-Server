//
//  routes.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 9/21/20.
//

import Vapor
import Fluent

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

func routes(_ application: Application) throws {
	application.get { (request) -> Response in
		return request.redirect(to: "https://web.shuttletracker.app")
	}
	application.get("testflight") { (request) -> Response in
		return request.redirect(to: "https://testflight.apple.com/join/GsmZkfgd")
	}
	application.get("version") { (_) -> UInt in
		return Constants.apiVersion
	}
	application.get("datafeed") { (_) throws -> String in
		return try String(contentsOf: Constants.datafeedURL)
	}
	application.get("routes") { (request) async throws -> [Route] in
		return try await Route.query(on: request.db)
			.all()
	}
	application.get("stops") { (request) async throws -> [Stop] in
		return try await Stop.query(on: request.db)
			.all()
	}
	application.get("buses") { (request) async throws -> [Bus.Resolved] in
		return try await Bus.query(on: request.db)
			.all()
			.compactMap { (bus) in
				return bus.resolved
			}
	}
	application.get("buses", "all") { (request) -> Set<Int> in
		return Buses.sharedInstance.allBusIDs
	}
	application.get("buses", ":id") { (request) async throws -> Bus.Location in
		guard let id = request.parameters.get("id", as: Int.self) else {
			throw Abort(.badRequest)
		}
		let buses = try await Bus.query(on: request.db)
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
	application.patch("buses", ":id") { (request) async throws -> Bus.Location? in
		guard let id = request.parameters.get("id", as: Int.self) else {
			throw Abort(.badRequest)
		}
		let location = try request.content.decode(Bus.Location.self)
		let bus = try await Bus.query(on: request.db)
			.filter(\.$id == id)
			.first()
		guard let bus = bus else {
			throw Abort(.notFound)
		}
		bus.locations.merge(with: [location])
		try await bus.update(on: request.db)
		return bus.locations.resolved
	}
	application.put("buses", ":id", "board") { (request) async throws -> Int? in
		guard let id = request.parameters.get("id", as: Int.self) else {
			throw Abort(.badRequest)
		}
		let bus = try await Bus.query(on: request.db)
			.filter(\.$id == id)
			.first()
		guard let bus = bus else {
			throw Abort(.notFound)
		}
		bus.congestion = (bus.congestion ?? 0) + 1
		try await bus.update(on: request.db)
		return bus.congestion
	}
	application.put("buses", ":id", "leave") { (request) async throws -> Int? in
		guard let id = request.parameters.get("id", as: Int.self) else {
			throw Abort(.badRequest)
		}
		let bus = try await Bus.query(on: request.db)
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
