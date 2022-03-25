//
//  funcInfo.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper. on 9/21/20.
//

import Vapor
import Fluent
import UAParserSwift

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

func funcInfo(_ application: Application) throws {
	// Fetch the user-agent string and redirect the user to the appropriate app distribution
	application.get { (request) -> Response in
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
	
	// Various redirects to certain distributions of the app
	application.get("swiftui") { (request) in
		return request.redirect(to: "https://apps.apple.com/us/app/shuttle-tracker/id1583503452")
	}
	application.get("swiftui", "beta") { (request) in
		return request.redirect(to: "https://testflight.apple.com/join/GsmZkfgd")
	}
	application.get("android") { (request) in
		return request.redirect(to: "https://play.google.com/store/apps/details?id=edu.rpi.shuttletracker")
	}
	application.get("android", "beta") { (request) in
		return request.redirect(to: "https://play.google.com/store/apps/details?id=edu.rpi.shuttletracker")
	}
	application.get("web") { (request) in
		return request.redirect(to: "https://web.shuttletracker.app")
	}
	application.get("web", "beta") { (request) in
		return request.redirect(to: "https://staging.web.shuttletracker.app")
	}
	application.get("beta") { (request) -> Response in
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
	application.get("testflight") { (request) in
		return request.redirect(to: "/swiftui/beta")
	}
	
	// Return the current version number of the API
	application.get("version") { (_) in
		return Constants.apiVersion
	}
	
	application.get("schedule") { (request) in
		return request.redirect(to: "/schedule.json")
	}
}
