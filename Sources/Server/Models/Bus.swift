//
//  Bus.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 9/21/20.
//

import FluentKit
import JSONParser
import Turf
import Vapor

/// A representation of a shuttle bus.
final class Bus: Hashable, Model {
	
	/// A representation of a single location datum.
	final class Location: Equatable, Content, Fields {
		
		enum LocationType: String, Codable, DatabaseEnum {
			
			case system, user, network
			
			static let name = #function
			
		}
		
		/// An identifier that’s used to update location data dynamically.
		/// - Important: Location reports from the same user during the same trip should all have the same ID value.
		@ID(custom: "id", generatedBy: .user)
		var id: UUID?
		
		/// A timestamp that indicates when this location datum was originally collected.
		@Field(key: "date")
		var date: Date
		
		/// The geospatial coordinate that’s associated with this location datum.
		@Field(key: "coordinate")
		var coordinate: Coordinate

		/// The type of location datum, which indicates how it was originally collected.
		@Enum(key: "type")
		var type: LocationType
		
		init() { }
		
		/// Create a location datum.
		/// - Parameters:
		///   - id: An identifier that’s used to update location data dynamically.
		///   - date: A timestamp that indicates when the location datum was originally collected.
		///   - coordinate: The geospatial coordinate that’s associated with the location datum.
		///   - type: The type of location datum, which indicates how it was originally collected.
		/// - Important: Location reports from the same user during the same trip should all have the same ID value.
		init(id: UUID, date: Date, coordinate: Coordinate, type: LocationType) {
			self.id = id
			self.date = date
			self.coordinate = coordinate
			self.type = type
		}
		
		static func == (lhs: Bus.Location, rhs: Bus.Location) -> Bool {
			return lhs.id == rhs.id
		}
		
	}
	
	/// A simplified representation of a ``Bus`` instance that’s suitable to return as a response to incoming requests.
	struct Resolved: Content {
		
		/// The physical bus’s unique identifier.
		var id: Int
		
		/// The current resolved location of the physical bus.
		var location: Bus.Location
		
		/// The route along which the bus is currently traveling.
		var routeID: UUID?
		
	}
	
	static let schema = "buses"
	
	/// A simplified representation of this bus that’s suitable to return as a response to incoming requests.
	var resolved: Resolved? {
		get {
			guard let id = self.id, let location = self.locations.resolved else {
				return nil
			}
			return Resolved(id: id, location: location, routeID: self.routeID)
		}
	}
	
	/// The physical bus’s unique identifier.
	@ID(custom: "id", generatedBy: .user)
	var id: Int?
	
	/// The location data for this bus.
	@Field(key: "locations")
	var locations: [Location]
	
	/// The congestion data for this bus.
	@OptionalField(key: "congestion")
	var congestion: Int?
	
	/// The ID of route along which this bus is currently traveling.
	@OptionalField(key: "route_id")
	var routeID: UUID?
	
	init() { }
	
	/// Creates a bus object.
	/// - Parameters:
	///   - id: The physical bus’s unique identifier.
	///   - locations: The location data for the bus.
	init(id: Int, locations: [Location] = []) {
		self.id = id
		self.locations = locations
	}
	
	func hash(into hasher: inout Hasher) {
		hasher.combine(self.id)
	}
	
	/// Detect the route along which this bus is currently traveling.
	func detectRoute(selectingFrom routes: [Route]) {
		guard let location = self.locations.resolved else {
			self.routeID = nil
			return
		}
		var selectedRoute: Route?
		for route in routes where route.checkIsOnRoute(location: location) {
			guard selectedRoute == nil else {
				return // Since the bus is currently in an overlapping portion of multiple routes, we leave the existing route association as-is.
			}
			selectedRoute = route
		}
		self.routeID = selectedRoute?.id
	}
	
	static func == (lhs: Bus, rhs: Bus) -> Bool {
		return lhs.id == rhs.id
	}
	
}

extension Collection where Element == Bus.Location {
	
	/// The resolved location datum from the bus’s GPS hardware.
	var systemLocation: Bus.Location? {
		get {
			return self.reversed().first { (location) -> Bool in
				return location.type == .system
			}
		}
	}
	
	/// The resolved location datum from Board Bus reports.
	var boardBusLocation: Bus.Location? {
		get {
			let userLocations = self.filter { (location) -> Bool in
				return .user ~= location.type
			}
			let networkLocations = self.filter { (location) in
				return .network ~= location.type
			}
			let locations = userLocations + networkLocations
			guard !locations.isEmpty else {
				return nil
			}
			let newestLocation = locations.max { (first, second) -> Bool in
				return first.date.compare(second.date) == .orderedAscending
			}
			let zeroCoordinate = Coordinate(latitude: 0, longitude: 0)
			var coordinate = locations.reduce(into: zeroCoordinate) { (coordinate, location) in
				coordinate += location.coordinate
			}
			coordinate /= Double(locations.count)
			guard let userCoordinate = coordinate == zeroCoordinate ? nil : coordinate else {
				return nil
			}
			return Bus.Location(
				id: UUID(),
				date: newestLocation?.date ?? Date(),
				coordinate: userCoordinate,
				type: networkLocations.isEmpty ? .user : .network
			)
		}
	}
	
	/// The final resolved location datum, which may or may not incorporate Board Bus data.
	var resolved: Bus.Location? {
		get {
			return self.boardBusLocation ?? self.systemLocation
		}
	}
	
}

extension Array: Mergeable where Element == Bus.Location {
	
	/// Merge other location data into this array.
	/// - Parameter otherLocations: The other location data to merge into this array.
	/// - Remark: This method implements a requirement in the ``Mergeable`` protocol.
	mutating func merge(with otherLocations: [Bus.Location]) {
		for otherLocation in otherLocations {
			self.removeAll { (location) in
				return location == otherLocation
			}
			self.append(otherLocation)
		}
	}
	
}
