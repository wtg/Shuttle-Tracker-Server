//
//  Milestone.swift
//  Shuttle Tracker Server
//
//  Created by Jose Luchsinger on 2/8/22.
//

import FluentKit
import Vapor

// A new “trip” is created every time someone boards a bus and creates a new identifier and is considered to be complete when that identifier stops responding after a certain period.

/// A representation of a milestone for the Community Milestones feature, which tracks various statistics and their progress towards a specific goal.
final class Milestone: VersionedModel, Content {
	
	/// A representation of a signed request to delete a particular milestone from the server.
	struct DeletionRequest: Decodable {
		
		/// A cryptographic signature of the unique identifier of the milestone to be deleted.
		let signature: Data
		
	}
	
	static let schema = "milestones"
	
	static let version: UInt = 1
	
	/// A unique identifier that’s used by the database.
	@ID
	var id: UUID?
	
	/// The full name of this milestone.
	@Field(key: "name")
	var name: String
	
	/// A human-readable description of this milestone.
	@Field(key: "extended_description")
	var extendedDescription: String
	
	/// The number of times that this milestone’s incrementation criterium has been met.
	@Field(key: "progress")
	var progress: Int
	
	/// A string that indicates the type of progress that this milestone tracks.
	///
	/// For example, the progress type of a milestone that tracks the number of times that any bus has been boarded might be set to `"BoardBusCount"`. All clients must agree on a list of acceptable values, but the server doesn’t need to care what values are, which is why this property is a string, not an enumeration.
	@Field(key: "progress_type")
	var progressType: String
	
	/// The goals for this milestone.
	///
	/// A single milestone might contain multiple goals, each of which would be represented by a single element in the array.
	/// - Important: The array might not always be sorted.
	@Field(key: "goals")
	var goals: [Int]
	
	/// A cryptographic signature of the concatenation of the `name` and `extendedDescription` properties as well as the string representation of the `goals` property, in that order.
	@Field(key: "signature")
	var signature: Data
	
	init() { }
	
}
