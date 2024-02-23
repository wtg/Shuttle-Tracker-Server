//
//  NotificationsDeviceController.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 1/12/24.
//

import FluentKit
import Vapor

/// A structure that registers routes for managing individual notifications devices.
/// - Remark: In the context of this structure, the term “route” refers to an HTTP route, not a shuttle route.
struct NotificationsDeviceController: RouteCollection {
	
	func boot(routes: RoutesBuilder) throws {
		routes.group(":token") { (routes) in
			routes.post(use: self.create(_:))
		}
	}
	
	private func create(_ request: Request) async throws -> APNSDevice {
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
