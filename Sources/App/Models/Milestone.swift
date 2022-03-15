//
//  Milestone.swift
//  Shuttle Tracker Server
//
//  Created by Jose Luchsinger on 2/8/22
//

import Vapor
import Fluent

// A new “trip” is created every time someone boards a bus and creates a new identifier and is considered to be complete when that identifier stops responding after a certain period.

/// A representation of a milestone for the Community Milestones feature, which tracks various statistics and their progress towards a specific goal.
final class Milestone: Model, Content {
	
	static let schema = "milestones"
	
	/// A unique identifier that’s used by the database.
	@ID var id: UUID?

	// TODO: Merge with the database identifier
	/// The shorthand name of this milestone.
	///
	/// For example, the shorthand name of a milestone that tracks the number of times that any bus has been boarded might be set to `"boardBusCount"`.
	@Field(key: "short") var short: String

	/// The full name of this milestone.
	@Field(key: "name") var name: String
	
	/// A human-readable description of this milestone.
	@Field(key: "description") var description: String

	/// The number of times that this milestone’s incrementation criterium has been met.
	@Field(key: "count") var count: Int

	/// The goals for this milestone.
	///
	/// A single milestone might contain multiple goals, each of which would be represented by a single element in the array.
	/// - Important: The array might not always be sorted.
	@Field(key: "goal") var goal: [Int]
	
	init() { }
	
}
