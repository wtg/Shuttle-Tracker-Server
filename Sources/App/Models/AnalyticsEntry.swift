//
//  AnalyticsEntry.swift
//  Shuttle Tracker Server
//
//  Created by Mahi Pasarkar on 2/18/2022.
//

//For more information read the wiki: https://github.com/wtg/Shuttle-Tracker-Server/wiki/Analytics

import Fluent
import Foundation
import Vapor

final class AnalyticsEntry: Model, Content {
	
	struct UserSettings: Codable {
		
		enum ColorTheme: String, Codable {
			case light, dark
		}
		
		let colorBlindMode: Bool?
		
		let colorTheme: ColorTheme?
		
	}
	
	static let schema = "analyticsentries"
	
	/// The unique identifier of this analytics entry.
	///
	/// This identifier is not the same as the user identifier, since one user may submit multiple analytics entries.
	@ID var id: UUID?
	
	/// The unique identifier of the user of the client that submitted this analytics entry.
	///
	/// To support privacy features and to account for users who might use Shuttle Tracker across different platforms, the identifier is unstable—_i.e._, it approximates a specific human user but is not guaranteed to remain the same as that user uses privacy features or moves across different client platforms. This property might be `nil` if there is no consistent user identity at all on the platform that submitted this analytics entry.
	@Field(key: "user_id") private(set) var userID: UUID?
	
	/// A timestamp that’s generated by the client.
	@Field(key: "date") private(set) var date: Date
	
	/// The client platform that submitted this analytics entry.
	@Field(key: "client_platform") private(set) var clientPlatform: String
	
	/// The client platform version string.
	///
	/// For native clients, this should be the OS version string (_e.g._, “15.3.1” on iOS). For Web clients, this should be the brand name of the user’s Web browser with no version information (_e.g._, “Safari”). All platform version strings should be consistently formatted per platform across different analytics submissions. This property might be `nil` if the OS version (or browser brand name) couldn’t be detected.
	@Field(key: "client_platform_version") private(set) var clientPlatformVersion: String?
	
	/// The app version string.
	///
	/// All app version strings should be consistently formatter per platform across different alaytics submissions.
	@Field(key: "app_version") private(set) var appVersion: String?
	
	/// The number of times that the user has used Board Bus so far since the last analytics submission for this user.
	@Field(key: "board_bus_count") private(set) var boardBusCount: Int?
	
	/// A record of the user’s current app settings as of the submission of this analytics entry.
	@Field(key: "user_settings") private(set) var userSettings: UserSettings
	
}
