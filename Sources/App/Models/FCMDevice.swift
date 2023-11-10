import FluentKit
import Vapor

final class FCMDevice: VersionedModel, Content {
	
	static let schema = "fcmdevices"
	
	static let version: UInt = 1
	
	@ID
	var id: UUID?
	
	@Field(key: "token")
	var token: String
	
	/// Initializes an invalid FCM device.
	/// - Warning: Do not use this initializer!
	init() { }
	
	init(token: String) {
		self.token = token
	}
	
}