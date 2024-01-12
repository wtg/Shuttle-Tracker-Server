//
//  ColorName.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 8/27/22.
//

enum ColorName: String, Codable, DatabaseEnum {
	
	case red, orange, yellow, green, blue, purple, pink, gray
	
	static let name = #function
	
}
