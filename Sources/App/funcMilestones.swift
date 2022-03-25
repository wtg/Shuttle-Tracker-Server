//
//  funcMilestones.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper
//


import Vapor
import Fluent
import UAParserSwift

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

func funcMilestones(_ application: Application) throws {
	// Get the current milestones
	application.get("milestones") { (request) in
		return try await Milestone
			.query(on: request.db(.psql))
			.all()
	} 
	
	application.post("milestones") { (request) -> Milestone in
		let milestone = try request.content.decode(Milestone.self)
		try await milestone.save(on: request.db(.psql))
		return milestone
	}
	
	// Increment a milestone with the given shorthand name
	application.patch("milestones", ":short") { (request) -> String in // TODO: Rename “short“ to “shortname“
		guard let short = request.parameters.get("short", as: String.self) else { // Get the supplied shorthand name from the request URL
			throw Abort(.badRequest)
		}
		let milestone = try await Milestone // Fetch the first milestone from the database with the appropriate shorthand name
			.query(on: request.db(.psql))
			.filter(\.$short == short)
			.first()
		guard let milestone = milestone else {
			throw Abort(.notFound)
		}
		
		milestone.count += 1 // Increment the milestone’s counter
		try await milestone.update(on: request.db(.psql)) // Update the milestone on the database
		return "Successfully incremented milestone “\(milestone.name)”"
	}
	
	//Delete a given milestone
	application.delete("milestones", ":short") { (request) -> String in
	guard let short = request.parameters.get("short", as: String.self) else { //request milestone with given short
		throw Abort(.badRequest)
	}

	try await Milestone //fetch milestone from database using short
		.query(on: request.db(.psql))
		.filter(\.$short == short)
		.delete()
		return "Deleted milestone " + short + "\n"
	}
}