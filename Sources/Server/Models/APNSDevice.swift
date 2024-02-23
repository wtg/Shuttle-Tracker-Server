//
//  APNSDevice.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 1/27/23.
//

import FluentKit
import Vapor

final class APNSDevice: VersionedModel, Content {
	
	static let schema = "apnsdevices"
	
	static let version: UInt = 1
	
	@ID
	var id: UUID?
	
	@Field(key: "token")
	var token: String
	
	/// Initializes an invalid APNS device.
	/// - Warning: Do not use this initializer!
	init() { }
	
	init(token: String) {
		self.token = token
	}
	
}
