//
//  Milestone.swift
//  Shuttle Tracker Server
//
//  Created by Jose Luchsinger on 2/8/22
//	
//	A "trip" is defined as every time someone boards a bus and creates a new identifier,
//  and is considered complete when that identifier stops responding after a certain period.

import Vapor
import Fluent

//	Defines the "Milestone" class, which tracks certain statistics and their progress towards a certain goal.
final class Milestone: Model, Content {
	
	static let schema = "milestones"
	
	@ID var id: UUID?
	
	// Name of the milestone.
	@Field(key: "name") var name: String
	
	// Description of the milestone.
	@Field(key: "description") var description: String

	// Keeps track of times the milestone criteria is met.
	@Field(key: "count") var count: Int

	//Upper bounds for count. Array of ints allows multiple goals/milestone "stages".
	@Field(key: "goal") var goal: [Int]
	
	init() { }
	
}
