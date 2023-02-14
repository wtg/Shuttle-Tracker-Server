//
//  AnalyticsEntry.swift
//  Shuttle Tracker Server
//
//  Created by Mahi Pasarkar on 2/18/2022.
//

import FluentKit
import Vapor

final class AnalyticsEntry: VersionedModel, Content {
	
	struct UserSettings: Codable {
		
		enum ColorTheme: String, Codable {
			
			case light, dark
			
		}
		
		let colorTheme: ColorTheme?
		
		let colorBlindMode: Bool?
		
		let debugMode: Bool?
		
		let logging: Bool?
		
		let maximumStopDistance: Int?
		
		let serverBaseURL: URL?
		
	}
		
	enum EventType: Codable {
		
		case coldLaunch
		
		case boardBusTapped
		
		case leaveBusTapped
		
		case boardBusActivated(manual: Bool)
		
		case boardBusDeactivated(manual: Bool)
		
		case busSelectionCanceled
		
		case announcementsListOpened
		
		case announcementViewed(id: UUID)
		
		case permissionsSheetOpened
		
		case networkToastPermissionsTapped
		
		case colorBlindModeToggled(enabled: Bool)
		
		case debugModeToggled(enabled: Bool)
		
		case serverBaseURLChanged(url: URL)
		
		case locationAuthorizationStatusDidChange(authorizationStatus: LocationAuthorizationStatus)
		
		case locationAccuracyAuthorizationDidChange(accuracyAuthorization: LocationAccuracyAuthorization)
		
	}
	
	static let schema = "analyticsentries"
	
	static var version: UInt = 2
	
	/// The unique identifier of this analytics entry.
	///
	/// This identifier is not the same as the user identifier, since one user may submit multiple analytics entries.
	@ID
	var id: UUID?
	
	/// The unique identifier of the user of the client that submitted this analytics entry.
	///
	/// To support privacy features and to account for users who might use Shuttle Tracker across different platforms, the identifier is unstable—_i.e._, it approximates a specific human user but is not guaranteed to remain the same as that user uses privacy features or moves across different client platforms. This property might be `nil` if there is no consistent user identity at all on the platform that submitted this analytics entry.
	@OptionalField(key: "user_id")
	private(set) var userID: UUID?
	
	/// A timestamp that’s generated by the client.
	@Field(key: "date")
	private(set) var date: Date
	
	/// The client platform that submitted this analytics entry.
	@Enum(key: "client_platform")
	private(set) var clientPlatform: ClientPlatform
	
	/// The client platform version string.
	///
	/// For native clients, this should be the OS version string (_e.g._, “15.3.1” on iOS). For Web clients, this should be the brand name of the user’s Web browser with no version information (_e.g._, “Safari”). All platform version strings should be consistently formatted per platform across different analytics submissions. This property might be `nil` if the OS version (or browser brand name) couldn’t be detected.
	@OptionalField(key: "client_platform_version")
	private(set) var clientPlatformVersion: String?
	
	/// The app version string.
	///
	/// All app version strings should be consistently formatter per platform across different analytics submissions.
	@OptionalField(key: "app_version")
	private(set) var appVersion: String?
	
	/// The number of times that the user has used Board Bus so far since the last analytics submission for this user.
	@OptionalField(key: "board_bus_count")
	private(set) var boardBusCount: Int?
	
	/// A record of the user’s current app settings as of the submission of this analytics entry.
	@Field(key: "user_settings")
	private(set) var userSettings: UserSettings
	
	/// The type of event that triggered the submission of this analytics entry.
	@Field(key: "event_type")
	private(set) var eventType: EventType?
	
}
