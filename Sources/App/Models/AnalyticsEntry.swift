//
//  AnalyticsEntry.swift
//  Shuttle Tracker Server
//
//  Created by Mahi Pasarkar on 2/18/2022.
//

//For more information read these documents:
//Analytics Blueprint: https://docs.google.com/document/d/1fPYbemSem0jyjARmP1f_-OFf8ygnclxX1s0tsAg0gEs/edit
//Sample JSON: https://docs.google.com/document/d/1SEF9Xt4keHo5Tf5Zy99QhsIYF3lD7z4PwLg7eZoHdAU/edit
//Server-side Handling: https://docs.google.com/document/d/1wyaDWdDawTB-A_AH0PsizAaZ4cDAjgV0iYDRSpuifyM/edit

import Vapor
import Fluent
import Foundation

final class AnalyticsEntry: Model, Content{

    static let schema = "analyticsentries"

    //UUID of user
    @Field(key: "uuid") var UUID: String

    //Date that the analytics data was last sent for this user (ISO 8601)
    @Field(key: "date_sent") var dateSent: String

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

    //Specific user settings, if True, setting is turned on
    struct UserSettings: Decodable {
        //This setting is on all platforms
        let colorBlindMode: Bool
        
        //This setting is only on web
        let darkMode: Bool
    }

    init () {}
}