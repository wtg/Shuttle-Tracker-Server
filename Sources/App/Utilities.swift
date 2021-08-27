//
//  Utilities.swift
//  Rensselaer Shuttle Server
//
//  Created by Gabriel Jacoby-Cooper on 8/27/21.
//

import Vapor

extension Optional: Content, RequestDecodable, ResponseEncodable where Wrapped: Codable { }

extension Set: Content, RequestDecodable, ResponseEncodable where Element: Codable { }
