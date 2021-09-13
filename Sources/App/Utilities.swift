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
	
}

extension Optional: Content, RequestDecodable, ResponseEncodable where Wrapped: Codable { }

extension Set: Content, RequestDecodable, ResponseEncodable where Element: Codable { }
