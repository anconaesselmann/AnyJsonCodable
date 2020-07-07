//  Created by Axel Ancona Esselmann on 6/30/20.
//  Copyright © 2020 Axel Ancona Esselmann. All rights reserved.
//

import Foundation

fileprivate struct JsonTypeWrapper {
    let wrapped: Any
    enum Error: Swift.Error { case notAJsonType }
}

extension JsonTypeWrapper: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(String.self) {
            wrapped = value
        } else if let value = try? container.decode(Bool.self) {
            wrapped = value
        } else if let value = try? container.decode(Int.self) {
            wrapped = value
        } else if let value = try? container.decode(Double.self) {
            wrapped = value
        } else if let value = try? container.decode([String: JsonTypeWrapper].self).jsonDictionary {
            wrapped = value
        } else if let value = try? container.decode([JsonTypeWrapper].self).jsonArray {
            wrapped = value
        } else {
            throw JsonTypeWrapper.Error.notAJsonType
        }
    }
}

extension JsonTypeWrapper: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let value = wrapped as? String {
            try container.encode(value)
        } else if let value = wrapped as? Bool {
            try container.encode(value)
        } else if let value = wrapped as? Int {
            try container.encode(value)
        } else if let value = wrapped as? Double {
            try container.encode(value)
        } else if let value = wrapped as? [String: Any] {
            try container.encode(value.mapValues { JsonTypeWrapper(wrapped: $0) })
        } else if let value = wrapped as? [Any] {
            try container.encode(value.map { JsonTypeWrapper(wrapped: $0) })
        } else {
            throw JsonTypeWrapper.Error.notAJsonType
        }
    }
}

public enum JsonValue {
    case string(String)
    case bool(Bool)
    case int(Int)
    case double(Double)
    case array([Any])
    case dictionary([String: Any])
    case unsupported(Any)
}

extension Dictionary where Value == JsonTypeWrapper {
    var jsonDictionary: [Key: Any] { mapValues { $0.wrapped } }
}

extension Array where Element == JsonTypeWrapper {
    var jsonArray: [Any] { map { $0.wrapped } }
}

public extension JSONDecoder {
    func decodeJsonDictionary(from data: Data) throws -> [String: Any] {
        try decode(Dictionary<String, JsonTypeWrapper>.self, from: data).jsonDictionary
    }
    func decodeJsonArray(from data: Data) throws -> [Any] {
        try decode(Array<JsonTypeWrapper>.self, from: data).jsonArray
    }
}

public extension JSONEncoder {
    func encode(_ jsonDict: [String: Any]) throws -> Data {
        try encode(jsonDict.mapValues { JsonTypeWrapper(wrapped: $0) })
    }

    func encode(_ jsonArray: [Any]) throws -> Data {
        try encode(jsonArray.map { JsonTypeWrapper(wrapped: $0) })
    }
}

public extension SingleValueDecodingContainer {
    func decodeJsonDictionary() throws -> [String: Any] {
        try decode(Dictionary<String, JsonTypeWrapper>.self).jsonDictionary
    }

    func decodeJsonArray() throws -> [Any] {
        try decode(Array<JsonTypeWrapper>.self).jsonArray
    }
}

public extension SingleValueEncodingContainer {
    mutating func encodeJsonDictionary(_ value: [String: Any]) throws {
        try encode(value.mapValues { JsonTypeWrapper(wrapped: $0) })
    }

    mutating func encodeJsonArray(_ value: [Any]) throws {
        try encode(value.map { JsonTypeWrapper(wrapped: $0) })
    }
}

public struct JsonDictionary: Codable, Sequence {
    public var raw: [String: Any]

    // This one is dangerous. Any could contain non-json items
    public init?(raw: [String: Any]?) {
        guard let raw = raw else {
            return nil
        }
        self.raw = raw
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        raw = try container.decodeJsonDictionary()
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        let wrapped = raw.mapValues { JsonTypeWrapper(wrapped: $0) }
        try container.encode(wrapped)
    }

    subscript (index: Dictionary<String, Any>.Index) -> Dictionary<String, Any>.Element? {
        return raw[index]
    }

    public func makeIterator() -> Dictionary<String, Any>.Iterator {
        raw.makeIterator()
    }

    public var jsonValues: [String: JsonValue] {
        raw.mapValues {
            switch $0 {
            case let value as String:
                return .string(value)
            case let value as Bool:
                return .bool(value)
            case let value as Int:
                return .int(value)
            case let value as Double:
                return .double(value)
            case let value as [Any]:
                return .array(value)
            case let value as [String: Any]:
                return .dictionary(value)
            default: return .unsupported($0)
            }
        }
    }
}

public struct JsonArray: Codable, Sequence {
    public var raw: [Any]

    // This one is dangerous. Any could contain non-json items
    public init?(raw: [Any]?) {
        guard let raw = raw else {
            return nil
        }
        self.raw = raw
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        raw = try container.decodeJsonArray()
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        let wrapped = raw.map { JsonTypeWrapper(wrapped: $0) }
        try container.encode(wrapped)
    }

    subscript (index: Array<Any>.Index) -> Array<Any>.Element {
        return raw[index]
    }

    public func makeIterator() -> Array<Any>.Iterator {
        raw.makeIterator()
    }

    public var jsonValues: [JsonValue] {
        raw.map {
            switch $0 {
            case let value as String:
                return .string(value)
            case let value as Bool:
                return .bool(value)
            case let value as Int:
                return .int(value)
            case let value as Double:
                return .double(value)
            case let value as [Any]:
                return .array(value)
            case let value as [String: Any]:
                return .dictionary(value)
            default: return .unsupported($0)
            }
        }
    }
}
