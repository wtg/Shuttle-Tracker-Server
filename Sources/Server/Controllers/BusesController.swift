//
//  BusesController.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 1/12/24.
//

import Vapor

/// A structure that registers routes for shuttle buses.
/// - Important: This structure registers routes on the index path of its provided routes builder, so make sure to enclose it in a named routes group to avoid path collisions.
/// - Remark: Unless otherwise specified, in the context of this structure, the term “route” refers to an HTTP route, not a shuttle route.
struct BusesController<DecoderType>: RouteCollection where DecoderType: ContentDecoder {
	
	private let decoder: DecoderType
	
	/// Initializes a new buses controller with the specified decoder.
    /// - Parameter decoder: An object that conforms to the `ContentDecoder` protocol, used for decoding the content of incoming requests.
    
	init(decoder: DecoderType) {
		self.decoder = decoder
	}
	
	/// Registers routes for reading specific or all shuttle bus data along with registering a nested route collection for individual bus management.
    /// - Parameter routes: A builder object for registering routes.
	func boot(routes: any RoutesBuilder) throws {
		routes.get(use: self.read(_:))
		routes.get("all", use: self.all(_:))
		try routes.register(collection: BusController(decoder: self.decoder))
	}

	/// Retrieves detailed resolved data for shuttle buses that are currently active on their routes.
    /// - Parameter request: A `Request` object encapsulating details about the incoming request.
    /// - Returns: An array of `Bus.Resolved` representing each active bus with details resolved based on their current route.
    /// - Throws: Throws an error if the bus data or route data could not be fetched from the database.
	private func read(_ request: Request) async throws -> [Bus.Resolved] {
		// In the context of this method, the term “route” refers to a shuttle route, not an HTTP route.
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
	/// Provides a set of all bus IDs currently tracked.
    /// - Parameter request: A `Request` object encapsulating details about the incoming request.
    /// - Returns: A set containing the IDs of all buses.
	private func all(_: Request) -> Set<Int> {
		return Buses.shared.allBusIDs
	}
	
}
