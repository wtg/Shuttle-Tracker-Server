//
//  NotificationsDevicesController.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 1/12/24.
//

import Vapor

/// A structure that registers routes for notifications devices.
/// - Remark: In the context of this structure, the term “route” refers to an HTTP route, not a shuttle route.
struct NotificationsDevicesController: RouteCollection {
	
	/// Registers a route collection that manages individual notification devices.
    /// - Parameter routes: A builder object for registering routes.
    /// - Throws: Throws an error if the route collection cannot be registered properly.
   
	func boot(routes: RoutesBuilder) throws {
		try routes.register(collection: NotificationsDeviceController())
	}
	
}
