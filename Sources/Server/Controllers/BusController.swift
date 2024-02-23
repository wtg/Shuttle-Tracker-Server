//
//  BusController.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 1/12/24.
//

import FluentKit
import Vapor

/// A structure that registers routes for managing individual shuttle buses.
/// - Remark: Unless otherwise specified, in the context of this structure, the term “route” refers to an HTTP route, not a shuttle route.
struct BusController<DecoderType>: RouteCollection where DecoderType: ContentDecoder {
	
	private let decoder: DecoderType
	
	init(decoder: DecoderType) {
		self.decoder = decoder
	}
	
	func boot(routes: any RoutesBuilder) throws {
		routes.group(":id") { (routes) in
			routes.get(use: self.read(_:))
			routes.patch(use: self.update(_:))
			routes.put("board", use: self.board(_:))
			routes.put("leave", use: self.leave(_:))
		}
	}
	
	private func read(_ request: Request) async throws -> Bus.Location {
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
	
	private func update(_ request: Request) async throws -> Bus.Resolved? {
		// In the context of this method, the term “route” refers to a shuttle route, not an HTTP route.
		guard let id = request.parameters.get("id", as: Int.self) else {
			throw Abort(.badRequest)
		}
		let location = try request.content.decode(Bus.Location.self, using: self.decoder)
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
		var bus = try await Bus
			.query(on: request.db(.sqlite))
			.filter(\.$id == id)
			.first()
		if id < 0 {
			let closestBus = try await Bus
				.query(on: request.db(.sqlite))
				.all()
				.filter { (candidate) in
					return candidate.locations.resolved.map { (candidateLocation) in
						return candidateLocation.coordinate.distance(to: location.coordinate) < 10
					} ?? false
				}
				.first
			if let closestBus {
				bus = closestBus
			} else {
				bus = Bus(id: id)
				try await bus!.save(on: request.db(.sqlite))
			}
		}
		guard let bus else {
			throw Abort(.notFound)
		}
		bus.locations.merge(with: [location])
		bus.detectRoute(selectingFrom: routes)
		try await bus.update(on: request.db(.sqlite))
		return bus.resolved
	}
	
	private func board(_ request: Request) async throws -> Int? {
		guard let id = request.parameters.get("id", as: Int.self) else {
			throw Abort(.badRequest)
		}
		let bus = try await Bus
			.query(on: request.db(.sqlite))
			.filter(\.$id == id)
			.first()
		guard let bus else {
			throw Abort(.notFound)
		}
		bus.congestion = (bus.congestion ?? 0) + 1
		try await bus.update(on: request.db(.sqlite))
		return bus.congestion
	}
	
	private func leave(_ request: Request) async throws -> Int? {
		guard let id = request.parameters.get("id", as: Int.self) else {
			throw Abort(.badRequest)
		}
		let bus = try await Bus
			.query(on: request.db(.sqlite))
			.filter(\.$id == id)
			.first()
		guard let bus else {
			throw Abort(.notFound)
		}
		bus.congestion = (bus.congestion ?? 1) - 1
		try await bus.update(on: request.db(.sqlite))
		return bus.congestion
	}
	
}
