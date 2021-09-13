//
//  Bus.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 9/21/20.
//

import Vapor
import Fluent

final class Bus: Hashable, Model {
	
	final class Location: Equatable, Content, Fields {
		
		enum LocationType: String, Codable {
			
			case system = "system"
			
			case user = "user"
			
		}
		
		@ID(custom: "id", generatedBy: .user) var id: UUID?
		
		@Field(key: "date") var date: Date
		
		@Field(key: "coordinate") var coordinate: Coordinate
		
		@Enum(key: "type") var type: LocationType
		
		init() { }
		
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
	
	struct Congestion: Content {
		
		enum Crowding: String, Codable {
			
			case notCrowded = "notCrowded"
			
			case crowded = "crowded"
			
			case completelyFull = "completelyFull"
			
		}
		
		struct Report: Codable, Comparable, Hashable {
			
			enum TransactionType: String, Codable {
				
				case boarding = "boarding"
				
				case leaving = "leaving"
				
				case update = "update"
				
			}
			
			let id: UUID
			
			let date: Date
			
			let coordinate: Coordinate
			
			let crowding: Crowding?
			
			let transactionType: TransactionType
			
			init(id: UUID = UUID(), date: Date = Date(), coordinate: Coordinate, crowding: Crowding? = nil, transactionType: TransactionType) {
				self.id = id
				self.date = date
				self.coordinate = coordinate
				self.crowding = crowding
				self.transactionType = transactionType
			}
			
			static func == (_ leftReport: Report, _ rightReport: Report) -> Bool {
				return leftReport.id == rightReport.id
			}
			
			static func < (_ leftReport: Bus.Congestion.Report, _ rightReport: Bus.Congestion.Report) -> Bool {
				return leftReport.date < rightReport.date
			}
			
			func hash(into hasher: inout Hasher) {
				hasher.combine(self.id)
			}
			
		}
		
		struct Resolved: Content {
			
			let crowding: Crowding?
			
		}
		
		var reports: Set<Report>
		
		var count: Int
		
		var resolved: Resolved {
			get {
				let reports = self.reports
					.sorted()
					.filter { (report) in
						return report.crowding != nil && report.date.timeIntervalSinceNow > -600
					}
				let fallbackCrowding: Crowding? = { 
					if self.count >= 10 {
						return .crowded
					} else if self.count >= 1 {
						return .notCrowded
					} else {
						return nil
					}
				}()
				return Resolved(crowding: reports.last?.crowding ?? fallbackCrowding)
			}
		}
		
		init(reports: Set<Report> = Set<Report>(), count: Int? = nil) {
			self.reports = reports
			if let count = count {
				self.count = count
			} else {
				self.count = self.reports.reduce(into: 0) { (partialResult, report) in
					switch report.transactionType {
					case .boarding:
						partialResult += 1
					case .leaving:
						partialResult -= 1
					default:
						break
					}
				}
			}
		}
		
		mutating func add(report: Report) {
			switch report.transactionType {
			case .boarding:
				self.count += 1
			case .leaving:
				self.count = max(self.count - 1, 0)
			case .update:
				self.reports.insert(report)
			}
		}
		
	}
	
	static let schema = "buses"
	
	var response: BusResponse? {
		get {
			guard let location = self.locations.resolvedLocation else {
				return nil
			}
			return BusResponse(id: self.id ?? 0, location: location)
		}
	}
	
	@ID(custom: "id", generatedBy: .user) var id: Int?
	
	@Field(key: "locations") var locations: [Location]
	
	@Field(key: "congestion") var congestion: Congestion
	
	init() { }
	
	init(id: Int, locations: [Location] = [], congestion: Congestion = Congestion()) {
		self.id = id
		self.locations = locations
		self.congestion = congestion
	}
	
	static func == (_ leftBus: Bus, _ rightBus: Bus) -> Bool {
		return leftBus.id == rightBus.id
	}
	
	func hash(into hasher: inout Hasher) {
		hasher.combine(self.id)
	}
	
}

struct BusResponse: Content {
	
	var id: Int
	
	var location: Bus.Location
	
}

extension Collection where Element == Bus {
	
	func save(on database: Database) {
		self.forEach { (bus) in
			_ = bus.save(on: database)
		}
	}
	
}

extension Set where Element == Bus {
	
	static func download(application: Application, _ busesCallback:  @escaping (Set<Bus>) -> Void) {
		_ = application.client.get("http://shuttles.rpi.edu/datafeed")
			.map { (response) in
				guard let length = response.body?.readableBytes, let data = response.body?.getData(at: 0, length: length), let rawString = String(data: data, encoding: .utf8) else {
					return
				}
				let buses = rawString.split(separator: "\r\n").dropFirst().dropLast().compactMap { (rawLine) -> Bus? in
					guard let idRange = rawLine.range(of: #"(?<=(Vehicle\sID:))\d+"#, options: [.regularExpression]), let id = Int(rawLine[idRange]) else {
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
				busesCallback(Set(buses))
			}
	}
	
}

extension Collection where Element == Bus.Location {
	
	var systemLocation: Bus.Location? {
		get {
			return self.reversed().first { (location) -> Bool in
				return location.type == .system
			}
		}
	}
	
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
	
	var resolvedLocation: Bus.Location? {
		get {
			return self.userLocation ?? self.systemLocation
		}
	}
	
}

extension Array: Mergeable where Element == Bus.Location {
	
	mutating func merge(with otherLocations: [Bus.Location]) {
		otherLocations.forEach { (location) in
			if let index = self.firstIndex(of: location) {
				self.remove(at: index)
			}
			self.append(location)
		}
	}
	
}
