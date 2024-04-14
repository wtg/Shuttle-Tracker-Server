//
//  RedirectsController.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 1/10/24.
//

import UAParserSwift
import Vapor

/// A structure that registers routes for various Web redirects.
/// - Remark: In the context of this structure, the term “route” refers to an HTTP route, not a shuttle route.
struct RedirectsController: RouteCollection {
	
	/// Registers routes for main, beta, and TestFlight redirects along with nested route collections for platform-specific redirects.
    /// - Parameter routes: A builder object for registering routes.
   
	func boot(routes: any RoutesBuilder) throws {
		routes.get(use: self.index(_:))
		routes.get("beta", use: self.beta(_:))
		routes.get("testflight", use: self.testflight(_:))
		try routes.group("swiftui") { (routes) in // Register the SwiftUI-redirect routes
			try routes.register(collection: SwiftUIRedirectsController())
		}
		try routes.group("android") { (routes) in // Register the Android-redirect routes
			try routes.register(collection: AndroidRedirectsController())
		}
		try routes.group("web") { (routes) in // Register the Web-redirect routes
			try routes.register(collection: WebRedirectsController())
		}
	}
	
	/// Fetches the user-agent string and redirect the user to the appropriate app distribution
	/// - Parameter request: The request.
	/// - Returns: The response.
	private func index(_ request: Request) -> Response {
		guard let agent = request.headers["User-Agent"].first else {
			return request.redirect(to: "/web")
		}
		let parser = UAParser(agent: agent)
		switch parser.os?.name?.lowercased() { // Switch on the user’s OS based on their user-agent string
		case "ios", "mac os":
			return request.redirect(to: "/swiftui")
		case "android":
			return request.redirect(to: "/android")
		default:
			return request.redirect(to: "/web")
		}
	}

	/// Redirects users to the beta section of their respective platform, based on the User-Agent header.
    /// - Parameter request: The request object containing the User-Agent header.
    /// - Returns: A redirect response to the beta section for the appropriate platform.
	private func beta(_ request: Request) -> Response {
		guard let agent = request.headers["User-Agent"].first else {
			return request.redirect(to: "/web/beta")
		}
		let parser = UAParser(agent: agent)
		switch parser.os?.name?.lowercased() {
		case "ios", "mac os":
			return request.redirect(to: "/swiftui/beta")
		case "android":
			return request.redirect(to: "/android/beta")
		default:
			return request.redirect(to: "/web/beta")
		}
	}
	
	/// Redirects users directly to the TestFlight beta section for iOS.
    /// - Parameter request: The request object.
    /// - Returns: A redirect response to the TestFlight beta page.
	private func testflight(_ request: Request) -> Response {
		return request.redirect(to: "/swiftui/beta")
	}
	
}
