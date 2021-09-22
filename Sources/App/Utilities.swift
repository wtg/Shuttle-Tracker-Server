//
//  Utilities.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 8/27/21.
//

import Vapor

enum Constants {
	
	/// The current version number for the API. Increment this value every time a breaking change is made to the public-facing API.
	static let apiVersion: UInt = 0
	
	static let datafeedURI: URI = {
		if let itrakString = ProcessInfo.processInfo.environment["itrak"] {
			return URI(string: itrakString)
		} else {
			return URI(stringLiteral: "https://shuttletracker.app/datafeed")
		}
	}()
	
}

extension Optional: Content, RequestDecodable, ResponseEncodable where Wrapped: Codable { }

extension Set: Content, RequestDecodable, ResponseEncodable where Element: Codable { }
