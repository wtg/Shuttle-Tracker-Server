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
	
	func boot(routes: RoutesBuilder) throws {
		try routes.register(collection: NotificationsDeviceController())
	}
	
}
