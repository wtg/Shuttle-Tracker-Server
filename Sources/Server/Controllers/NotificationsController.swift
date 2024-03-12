//
//  NotificationsController.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 1/12/24.
//

import Vapor

/// A structure that registers routes for notifications.
/// - Remark: In the context of this structure, the term “route” refers to an HTTP route, not a shuttle route.
struct NotificationsController: RouteCollection {
	
	func boot(routes: RoutesBuilder) throws {
		try routes.register(collection: NotificationsDevicesController(), on: "devices")
	}
	
}
