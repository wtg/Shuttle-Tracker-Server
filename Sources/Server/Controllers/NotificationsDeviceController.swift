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
	
	/// Registers routes for managing individual notification devices, particularly for creating new device entries.
    /// - Parameter routes: A builder object for registering routes.
    /// - Throws: Throws an error if the routes cannot be registered properly.
   
	func boot(routes: RoutesBuilder) throws {
		routes.group(":token") { (routes) in
			routes.post(use: self.create(_:))
		}
	}
	
	/// Creates or retrieves an existing notification device based on the provided token.
    /// - Parameter request: A `Request` object encapsulating details about the incoming request, specifically the device token.
    /// - Returns: An `APNSDevice` object representing the notification device.
    /// - Throws: An `Abort` error if no token is provided (400) or if database operations fail.
    
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
