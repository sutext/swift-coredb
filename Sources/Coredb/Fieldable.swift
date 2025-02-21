//
//  Fieldable.swift
//  swift-coredb
//
//  Created by supertext on 2024/3/29.
//

import Foundation

public protocol Fieldable: Codable,Equatable,Hashable{
    func writein() -> Any?
    static func readout(_ data:Any) -> Self?
}
/// Default implemention of Fieldable
public extension Fieldable{
    @inlinable func writein() -> Any?{ self }
    @inlinable static func readout(_ data:Any) -> Self?{ data as? Self }
}
public extension Fieldable where Self:RawRepresentable{
    @inlinable func writein() -> Any?{ self.rawValue }
    @inlinable static func readout(_ data:Any) -> Self?{
        if let raw = data as? Self.RawValue{
            return Self.init(rawValue: raw)
        }
        return nil
    }
}

extension Bool:Fieldable{}
extension UUID:Fieldable{}
extension Date:Fieldable{}
extension Int:Fieldable{}
extension Int8:Fieldable{}
extension Int16:Fieldable{}
extension Int32:Fieldable{}
extension Int64:Fieldable{}
extension UInt:Fieldable{}
extension UInt8:Fieldable{}
extension UInt16:Fieldable{}
extension UInt32:Fieldable{}
extension UInt64:Fieldable{}
extension Float32:Fieldable{}
extension Float64:Fieldable{}
extension String:Fieldable{}


extension Optional:Fieldable where Wrapped:Fieldable{
    @inlinable public func writein() -> Any?{ self?.writein() }
    @inlinable public static func readout(_ data:Any) -> Self?{ Wrapped.readout(data) }
}
extension Array:Fieldable where Element:Fieldable{
    @inlinable public func writein() -> Any? { try? JSONEncoder().encode(self) }
    @inlinable public static func readout(_ data: Any) -> Self? {
        if let raw = data as? Data{
            return try? JSONDecoder().decode(Self.self, from: raw)
        }
        return nil
    }
}
extension Dictionary:Fieldable where Value:Fieldable,Key:Codable{
    @inlinable public func writein() -> Any? { try? JSONEncoder().encode(self) }
    @inlinable public static func readout(_ data: Any) -> Self? {
        if let raw = data as? Data{
            return try? JSONDecoder().decode(Self.self, from: raw)
        }
        return nil
    }
}
// MARK: JSONFieldable
/// Default implemention of JSONFieldable
public protocol JSONFieldable: Fieldable{}
public extension JSONFieldable{
    @inlinable func writein() -> Any? { try? JSONEncoder().encode(self) }
    @inlinable static func readout(_ data: Any) -> Self? {
        if let raw = data as? Data{
            return try? JSONDecoder().decode(Self.self, from: raw)
        }
        return nil
    }
}
