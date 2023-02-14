//
//  ClientPlatform.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 1/14/23.
//

enum ClientPlatform: String, Codable, DatabaseEnum {
	
	case ios, macos, android, web
	
	static let name = #function
	
}
