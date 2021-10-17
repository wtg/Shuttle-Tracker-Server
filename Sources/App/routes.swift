//
//  routes.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 9/21/20.
//

import Vapor
import Fluent

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
	application.get("datafeed") { (_) -> EventLoopFuture<String> in
		return application.client.get(Constants.datafeedURI)
			.flatMapThrowing { (response) in
				if response.status.code != 200 {
					throw Abort(.failedDependency)
				}
				guard let length = response.body?.readableBytes, let rawString = response.body?.getString(at: 0, length: length) else {
					throw Abort(.failedDependency)
				}
				return rawString
			}
	}
	application.get("routes") { (request) -> EventLoopFuture<[Route]> in
		return Route.query(on: request.db)
			.all()
	}
	application.get("stops") { (request) -> EventLoopFuture<[Stop]> in
		return Stop.query(on: request.db)
			.all()
	}
	application.get("buses") { (request) -> EventLoopFuture<[Bus.Resolved]> in
		return Bus.query(on: request.db)
			.all()
			.flatMapEachCompactThrowing { (bus) -> Bus.Resolved? in
				return bus.resolved
			}
	}
	application.get("buses", "all") { (request) -> Set<Int> in
		return Buses.sharedInstance.allBusIDs
	}
	application.get("buses", ":id") { (request) -> EventLoopFuture<Bus.Location> in
		guard let id = request.parameters.get("id", as: Int.self) else {
			throw Abort(.badRequest)
		}
		return Bus.query(on: request.db)
			.filter(\.$id == id)
			.all()
			.flatMapThrowing { (buses) -> Bus.Location in
				let locations = buses.flatMap { (bus) -> [Bus.Location] in
					return bus.locations
				}
				guard let location = locations.resolved else {
					throw Abort(.notFound)
				}
				return location
			}
	}
	application.patch("buses", ":id") { (request) -> EventLoopFuture<[Bus.Location]> in
		guard let id = request.parameters.get("id", as: Int.self) else {
			throw Abort(.badRequest)
		}
		let location = try request.content.decode(Bus.Location.self)
		return Bus.query(on: request.db)
			.filter(\.$id == id)
			.first()
			.unwrap(or: Abort(.notFound))
			.map { (bus) -> [Bus.Location] in
				bus.locations.merge(with: [location])
				_ = bus.update(on: request.db)
				return bus.locations
			}
	}
	application.put("buses", ":id", "board") { (request) -> EventLoopFuture<Int?> in
		guard let id = request.parameters.get("id", as: Int.self) else {
			throw Abort(.badRequest)
		}
		return Bus.query(on: request.db)
			.filter(\.$id == id)
			.first()
			.unwrap(or: Abort(.notFound))
			.map { (bus) -> Int? in
				bus.congestion = (bus.congestion ?? 0) + 1
				_ = bus.update(on: request.db)
				return bus.congestion
			}
	}
	application.put("buses", ":id", "leave") { (request) -> EventLoopFuture<Int?> in
		guard let id = request.parameters.get("id", as: Int.self) else {
			throw Abort(.badRequest)
		}
		return Bus.query(on: request.db)
			.filter(\.$id == id)
			.first()
			.unwrap(or: Abort(.notFound))
			.flatMapThrowing { (bus) -> Int? in
				bus.congestion = (bus.congestion ?? 1) - 1
				_ = bus.update(on: request.db)
				return bus.congestion
			}
	}
}
