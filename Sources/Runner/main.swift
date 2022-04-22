//
//  main.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 9/21/20.
//

import Vapor
import App

Task {
	var environment = try Environment.detect()
	try LoggingSystem.bootstrap(from: &environment)
	let app = Application(environment)
	defer {
		app.shutdown()
	}
	try await configure(app)
	try app.run()
}
