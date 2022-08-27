//
//  ColorName.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 8/27/22.
//

enum ColorName: String, CaseIterable, Codable {
	
	case red, orange, yellow, green, blue, purple, pink, brown, gray
	
	static let sqlName = "ColorName"
	
}
