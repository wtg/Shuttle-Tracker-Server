//
//  AnalyticsEntry.swift
//  Shuttle Tracker Server
//
//  Created by Mahi Pasarkar on 2/18/2022.
//

//For more information read the wiki: https://github.com/wtg/Shuttle-Tracker-Server/wiki/Analytics

import Vapor
import Fluent
import Foundation

final class AnalyticsEntry: Model, Content {

    static let schema = "analyticsentries"

    @ID var id: UUID?

    //UUID of user
    @Field(key: "user_id") var userID: String

    //Date that the analytics data was last sent for this user (ISO 8601)
    @Field(key: "date_sent") var dateSent: Date

    //What platform the user is on (iOS/Android/Web)
    @Field(key: "platform") var platform: String

    //What version the user's software is on
    //E.g. for iOS: "15.3.1"
    //For Web, write browser 
    //e.g "Chrome" or "Firefox" or "Other" (You can include more browsers than this)
    @Field(key: "version") var version: String

    //Whether user has ever used the Board Bus
    @Field(key: "used_board") var usedBoard: Bool

    //Number of times user has used Board Bus per month. Will be reset every month
    @Field(key: "times_boarded") var timesBoarded: Int

    struct UserSettings: Codable {
        //This setting is on all platforms
        let colorBlindMode: Bool?
        
        //This setting is only on web
        let darkMode: Bool?
    }
    //Specific user settings, if True, setting is turned on
    @Field(key: "user_settings") var userSettings: UserSettings

    init () {}
}