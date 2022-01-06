//
//  Bus.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 9/21/20.
//

import Vapor
import Fluent
import JSONParser

/// A representation of a shuttle bus.
final class Bus: Hashable, Model {
	
	enum Direction: String, Codable {
		
		case a = "a"
		
		case b = "b"
		
	}
	
	/// A representation of a single location datum.
	final class Location: Equatable, Content, Fields {
		
		enum LocationType: String, Codable {
			
			case system = "system"
			
			case user = "user"
			
		}
		
		/// An identifier that's used to update location data dynamically. Location reports from the same user during the same trip should all have the same value.
		@ID(custom: "id", generatedBy: .user) var id: UUID?
		
		/// A timestamp that indicates when this location datum was originally collected.
		@Field(key: "date") var date: Date
		
		/// The geospatial coordinate that's associated with this location datum.
		@Field(key: "coordinate") var coordinate: Coordinate
		
		/// The type of location datum, which indicates how it was originally collected.
		@Enum(key: "type") var type: LocationType
		
		init() { }
		
		/// Create a new location datum.
		/// - Parameters:
		///   - id: An identifier that's used to update location data dynamically. Location reports from the same user during the same trip should all have the same value.
		///   - date: A timestamp that indicates when the location datum was originally collected.
		///   - coordinate: The geospatial coordinate that's associated with the location datum.
		///   - type: The type of location datum, which indicates how it was originally collected.
		init(id: UUID, date: Date, coordinate: Coordinate, type: LocationType) {
			self.id = id
			self.date = date
			self.coordinate = coordinate
			self.type = type
		}
		
		static func == (_ leftLocation: Bus.Location, _ rightLocation: Bus.Location) -> Bool {
			return leftLocation.id == rightLocation.id
		}
		
	}
	
	/// A simplified representation of a `Bus` instance that's suitable for returning as a response to incoming requests.
	struct Resolved: Content {
		
		/// The physical bus's unique identifier.
		var id: Int
		
		/// The current resolved location of the physical bus.
		var location: Bus.Location
		
	}
	
	static let schema = "buses"
	
	/// A simplified representation of this `Bus` instance that's suitable for returning as a response to incoming requests.
	var resolved: Resolved? {
		get {
			guard let id = self.id else {
				return nil
			}
			guard let location = self.locations.resolved else {
				return nil
			}
			return Resolved(id: id, location: location)
		}
	}
	
	/// The physical bus's unique identifier.
	@ID(custom: "id", generatedBy: .user) var id: Int?
	
	/// The location data for this bus.
	@Field(key: "locations") var locations: [Location]
	
	/// The congestion data representation for this bus.
	@OptionalField(key: "congestion") var congestion: Int?
	
	/// The direction in which this bus is currently traveling along its route.
	@OptionalEnum(key: "direction") var direction: Direction?
	
	init() { }
	
	/// Create a new bus object.
	/// - Parameters:
	///   - id: The physical bus's unique identifier.
	///   - locations: The location data for the bus.
	init(id: Int, locations: [Location] = [], direction: Direction? = nil) {
		self.id = id
		self.locations = locations
		self.direction = direction
	}
	
	static func == (_ leftBus: Bus, _ rightBus: Bus) -> Bool {
		return leftBus.id == rightBus.id
	}
	
	func hash(into hasher: inout Hasher) {
		hasher.combine(self.id)
	}
	
	func updateDirection(on database: Database) async throws {
		// TODO: Handle multiple routes
		let route = try await Route
			.query(on: database)
			.first()
		
		let recentLocations = self.locations.filter { (location) in
			return route?.check(location: location) ?? false && location.date.timeIntervalSinceNow > -600
		}
		let stops = try await Stop
			.query(on: database)
			.all()
		
		// TODO: Finish calculating direction
	}
	
}

extension Collection where Element == Bus {
	
	/// Save each bus object in this collection.
	/// - Parameter database: The database on which to save the bus objects.
	func save(on database: Database) {
		self.forEach { (bus) in
			_ = bus.save(on: database)
		}
	}
	
}

extension Set where Element == Bus {
	
	/// Download the latest system bus data.
	/// - Parameters:
	///   - application: The current application object.
	///   - busesCallback: A callback that's given a `Set<Bus>` instance with new bus objects. Note that these bus objects will **not** contain any user-reported location or congestion data and therefore must be separately merged with any existing bus data.
	static func download(application: Application) async throws -> Set<Bus> {
		let rawString = try String(contentsOf: Constants.datafeedURL)
		let buses = rawString.split(separator: "\r\n")
			.dropFirst()
			.dropLast()
			.compactMap { (rawLine) -> Bus? in
				guard let backendIDRange = rawLine.range(of: #"(?<=(Vehicle\sID:))\d+"#, options: [.regularExpression]) else {
					return nil
				}
				guard let latitudeRange = rawLine.range(of: #"(?<=(lat:))-?\d+\.\d+"#, options: [.regularExpression]), let latitude = Double(rawLine[latitudeRange]) else {
					return nil
				}
				guard let longitudeRange = rawLine.range(of: #"(?<=(lon:))-?\d+\.\d+"#, options: [.regularExpression]), let longitude = Double(rawLine[longitudeRange]) else {
					return nil
				}
				guard let timeRange = rawLine.range(of: #"(?<=(time:))\d+"#, options: [.regularExpression]), let dateRange = rawLine.range(of: #"(?<=(date:))\d{8}"#, options: [.regularExpression]) else {
					return nil
				}
				let backendID = String(rawLine[backendIDRange])
				guard let id = Buses.sharedInstance.busIDMap[backendID] else {
					return nil
				}
				let formatter = DateFormatter()
				formatter.dateFormat = "HHmmss'|'MMddyyyy"
				formatter.timeZone = TimeZone(abbreviation: "UTC")!
				let dateString = "\(rawLine[timeRange])|\(rawLine[dateRange])"
				guard let date = formatter.date(from: dateString) else {
					return nil
				}
				let coordinate = Coordinate(latitude: latitude, longitude: longitude)
				let location = Bus.Location(id: UUID(), date: date, coordinate: coordinate, type: .system)
				return Bus(id: id, locations: [location])
			}
		return Set(buses)
	}
	
}

extension Collection where Element == Bus.Location {
	
	/// The resolved location datum from the bus's GPS hardware.
	var systemLocation: Bus.Location? {
		get {
			return self.reversed().first { (location) -> Bool in
				return location.type == .system
			}
		}
	}
	
	/// The resolved location datum from user reports.
	var userLocation: Bus.Location? {
		get {
			let userLocations = self.filter { (location) -> Bool in
				return location.type == .user
			}
			guard userLocations.count > 0 else {
				return nil
			}
			let newestLocation = userLocations.max { (firstLocation, secondLocation) -> Bool in
				return firstLocation.date.compare(secondLocation.date) == .orderedAscending
			}
			let zeroCoordinate = Coordinate(latitude: 0, longitude: 0)
			var coordinate = userLocations.reduce(into: zeroCoordinate) { (coordinate, location) in
				coordinate += location.coordinate
			}
			coordinate /= Double(userLocations.count)
			guard let userCoordinate = coordinate == zeroCoordinate ? nil : coordinate else {
				return nil
			}
			return Bus.Location(id: UUID(), date: newestLocation?.date ?? Date(), coordinate: userCoordinate, type: .user)
		}
	}
	
	/// The final resolved location datum, which may or may not incorporate user-reported data.
	var resolved: Bus.Location? {
		get {
			return self.userLocation ?? self.systemLocation
		}
	}
	
}

extension Array: Mergeable where Element == Bus.Location {
	
	/// Merge other location data into this array.
	/// - Parameter otherLocations: The other location data to merge into this array.
	/// - Note: This method implements a requirement in the `Mergeable` protocol.
	mutating func merge(with otherLocations: [Bus.Location]) {
		otherLocations.forEach { (location) in
			if let index = self.firstIndex(of: location) {
				self.remove(at: index)
			}
			self.append(location)
		}
	}
	
}
