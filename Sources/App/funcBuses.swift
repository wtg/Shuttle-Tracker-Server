//
//  funcBuses.swift
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

func funcBuses(_ application: Application) throws {
	// Attempt to fetch and to return the shuttle buses
	application.get("buses") { (request) -> [Bus.Resolved] in
		let routes = try await Route
			.query(on: request.db)
			.all()
		return try await Bus
			.query(on: request.db)
			.all()
			.compactMap { (bus) in
				return bus.resolved
			}
			.filter { (resolved) in
				return !routes.allSatisfy { (route) in
					return !route.checkIfValid(location: resolved.location)
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
	
	// Attempt to update a bus’s location
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
	
	// Indicate that a user has boarded the bus with the given ID number
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
	
	// Indicate that a user has left the bus with the given ID number
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
