//
//  Downloaders.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 11/1/21.
//

import Vapor
import Fluent

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif // canImport(FoundationNetworking)

enum Downloaders {
	
	/// Download the latest system bus data.
	/// - Parameter application: The current application object.
	/// - Returns: The new bus objects.
	/// - Important: The returned bus objects will **not** contain any user-reported location or congestion data and therefore must be separately merged with any existing bus data.
	static func getBuses(on application: Application) async throws -> [Bus] {
		return try await withCheckedThrowingContinuation { (continuation) in
			let dataTask = URLSession.shared.dataTask(with: Constants.datafeedURL) { (data, _, error) in
				guard let data = data else {
					continuation.resume(throwing: error ?? NetworkError.unknown)
					return
				}
				guard let rawString = String(data: data, encoding: .utf8) else {
					continuation.resume(throwing: NetworkError.invalidResponseEncoding)
					return
				}
				do {
					let buses = try rawString
						.split(separator: "\r\n")
						.dropFirst()
						.compactMap { (line) -> Bus? in
							guard let backendIDRange = line.range(of: #"(?<=(Vehicle\sID:))\d+"#, options: [.regularExpression]) else {
								return nil
							}
							guard let latitudeRange = line.range(of: #"(?<=(lat:))-?\d+\.\d+"#, options: [.regularExpression]), let latitude = Double(line[latitudeRange]) else {
								return nil
							}
							guard let longitudeRange = line.range(of: #"(?<=(lon:))-?\d+\.\d+"#, options: [.regularExpression]), let longitude = Double(line[longitudeRange]) else {
								return nil
							}
							guard let timeRange = line.range(of: #"(?<=(time:))\d+"#, options: [.regularExpression]), let dateRange = line.range(of: #"(?<=(date:))\d{8}"#, options: [.regularExpression]) else {
								return nil
							}
							let backendID = String(line[backendIDRange])
							guard let id = Buses.shared.busIDMap[backendID] else {
								return nil
							}
							let formatter = DateFormatter()
							formatter.dateFormat = "HHmmss'|'MMddyyyy"
							formatter.timeZone = TimeZone(abbreviation: "UTC")!
							let dateString = "\(line[timeRange])|\(line[dateRange])"
							guard var date = formatter.date(from: dateString) else {
								return nil
							}
							let coordinate = Coordinate(latitude: latitude, longitude: longitude)
							if date > Date.now {
								let oldBusFuture = Bus.query(on: application.db)
									.filter(\.$id == id)
									.first()
								let oldBus = try oldBusFuture.wait()
								if let oldLocation = oldBus?.locations.resolved, oldLocation.coordinate == coordinate {
									date = oldLocation.date
								} else {
									date = .now
								}
							}
							let location = Bus.Location(id: UUID(), date: date, coordinate: coordinate, type: .system)
							return Bus(id: id, locations: [location])
						}
					continuation.resume(returning: buses)
				} catch let parseError {
					continuation.resume(throwing: parseError)
				}
			}
			dataTask.resume()
		}
	}
	
}
