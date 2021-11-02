//
//  Utilities.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 8/27/21.
//

import Foundation
import Vapor

enum Constants {
	
	/// The current version number for the API. Increment this value every time a breaking change is made to the public-facing API.
	static let apiVersion: UInt = 0
	
	static let datafeedURL: URL = {
		if let itrakString = ProcessInfo.processInfo.environment["ITRAK"] {
			return URL(string: itrakString)!
		} else {
			return URL(string: "https://shuttletracker.app/datafeed")!
		}
	}()
	
}

extension Optional: Content, RequestDecodable, ResponseEncodable, AsyncRequestDecodable, AsyncResponseEncodable where Wrapped: Codable { }

extension Set: Content, RequestDecodable, ResponseEncodable, AsyncRequestDecodable, AsyncResponseEncodable where Element: Codable { }

#if os(Linux)
extension Date {
	
	static var now: Date {
		get {
			return Date()
		}
	}
	
}
#endif // os(Linux)
