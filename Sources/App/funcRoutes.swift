//
//  funcRoutes.swift
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

func funcRoutes(_ application: Application) throws {
	// Return the contents of the datafeed
	application.get("datafeed") { (_) in
		return try String(contentsOf: Constants.datafeedURL)
	}
	
	// Attempt to fetch and to return the shuttle routes
	application.get("routes") { (request) in
		return try await Route
			.query(on: request.db)
			.all()
	}
	
	// Attempt to fetch and to return the shuttle stops
	application.get("stops") { (request) in
		return try await Stop
			.query(on: request.db)
			.all()
	}
	
	application.get("stops", ":shortname") { (request) in
		return request.redirect(to: "/", type: .temporary)
	}
}
