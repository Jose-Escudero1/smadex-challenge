//
//  FeatureFlagValue.swift
//  FeatureFlagsKit
//
//  Created by Jose Escudero on 21/6/26.
//

import Foundation


public enum FeatureFlagValue: Equatable, Sendable {
    case bool(Bool)
    case int(Int)
    case double(Double)
    case string(String)
    case codable(Data)
}

// MARK: - Creación a partir de tipos Codable

public extension FeatureFlagValue {
    static func encoding<T: Encodable>(_ value: T) throws -> FeatureFlagValue {
        let data = try JSONEncoder().encode(value)
        return .codable(data)
    }
}

// MARK: - Persistencia

extension FeatureFlagValue: Codable {

    private enum CodingKeys: String, CodingKey {
        case type
        case value
    }

    private enum Discriminator: String, Codable {
        case bool, int, double, string, codable
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(Discriminator.self, forKey: .type)
        switch type {
        case .bool:
            self = .bool(try container.decode(Bool.self, forKey: .value))
        case .int:
            self = .int(try container.decode(Int.self, forKey: .value))
        case .double:
            self = .double(try container.decode(Double.self, forKey: .value))
        case .string:
            self = .string(try container.decode(String.self, forKey: .value))
        case .codable:
            self = .codable(try container.decode(Data.self, forKey: .value))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .bool(let value):
            try container.encode(Discriminator.bool, forKey: .type)
            try container.encode(value, forKey: .value)
        case .int(let value):
            try container.encode(Discriminator.int, forKey: .type)
            try container.encode(value, forKey: .value)
        case .double(let value):
            try container.encode(Discriminator.double, forKey: .type)
            try container.encode(value, forKey: .value)
        case .string(let value):
            try container.encode(Discriminator.string, forKey: .type)
            try container.encode(value, forKey: .value)
        case .codable(let value):
            try container.encode(Discriminator.codable, forKey: .type)
            try container.encode(value, forKey: .value)
        }
    }
}
