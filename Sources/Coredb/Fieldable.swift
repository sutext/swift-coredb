//
//  Fieldable.swift
//  swift-coredb
//
//  Created by supertext on 2024/3/29.
//

import Foundation

public protocol Fieldable: Codable,Hashable{
    func writein() -> Any?
    static func readout(_ data:Any) -> Self?
}
extension Bool:Fieldable{
    @inlinable public func writein() -> Any?{ self }
    @inlinable static public func readout(_ data:Any) -> Self?{ data as? Self }
}
extension UUID:Fieldable{
    @inlinable public func writein() -> Any?{ self }
    @inlinable static public func readout(_ data:Any) -> Self?{ data as? Self }
}
extension Date:Fieldable{
    @inlinable public func writein() -> Any?{ self }
    @inlinable static public func readout(_ data:Any) -> Self?{ data as? Self }
}
extension Int:Fieldable{
    @inlinable public func writein() -> Any?{ self }
    @inlinable static public func readout(_ data:Any) -> Self?{ data as? Self }
}
extension Int8:Fieldable{
    @inlinable public func writein() -> Any?{ self }
    @inlinable static public func readout(_ data:Any) -> Self?{ data as? Self }
}
extension Int16:Fieldable{
    @inlinable public func writein() -> Any?{ self }
    @inlinable static public func readout(_ data:Any) -> Self?{ data as? Self }
}
extension Int32:Fieldable{
    @inlinable public func writein() -> Any?{ self }
    @inlinable static public func readout(_ data:Any) -> Self?{ data as? Self }
}
extension Int64:Fieldable{
    @inlinable public func writein() -> Any?{ self }
    @inlinable static public func readout(_ data:Any) -> Self?{ data as? Self }
}
extension UInt:Fieldable{
    @inlinable public func writein() -> Any?{ self }
    @inlinable static public func readout(_ data:Any) -> Self?{ data as? Self }
}
extension UInt8:Fieldable{
    @inlinable public func writein() -> Any?{ self }
    @inlinable static public func readout(_ data:Any) -> Self?{ data as? Self }
}
extension UInt16:Fieldable{
    @inlinable public func writein() -> Any?{ self }
    @inlinable static public func readout(_ data:Any) -> Self?{ data as? Self }
}
extension UInt32:Fieldable{
    @inlinable public func writein() -> Any?{ self }
    @inlinable static public func readout(_ data:Any) -> Self?{ data as? Self }
}
extension UInt64:Fieldable{
    @inlinable public func writein() -> Any?{ self }
    @inlinable static public func readout(_ data:Any) -> Self?{ data as? Self }
}
extension Float:Fieldable{
    @inlinable public func writein() -> Any?{ self }
    @inlinable static public func readout(_ data:Any) -> Self?{ data as? Self }
}
extension Double:Fieldable{
    @inlinable public func writein() -> Any?{ self }
    @inlinable static public func readout(_ data:Any) -> Self?{ data as? Self }
}
extension String:Fieldable{
    @inlinable public func writein() -> Any?{ self }
    @inlinable static public func readout(_ data:Any) -> Self?{ data as? Self }
}
extension Optional:Fieldable where Wrapped:Fieldable{
    @inlinable public func writein() -> Any?{ self?.writein() }
    @inlinable public static func readout(_ data:Any) -> Self?{ Wrapped.readout(data) }
}
extension Set:Fieldable where Element:Fieldable{}
extension Array:Fieldable where Element:Fieldable{}
extension Dictionary:Fieldable where Value:Fieldable,Key:Codable{}

/// Use RawValue Type in the `xcdatamodeld`
public extension Fieldable where Self:RawRepresentable{
    @inlinable func writein() -> Any?{ self.rawValue }
    @inlinable static func readout(_ data:Any) -> Self?{
        if let raw = data as? Self.RawValue{
            return Self.init(rawValue: raw)
        }
        return nil
    }
}
///Use BinaryData type in the `xcdatamodeld`
public extension Fieldable{
    @inlinable func writein() -> Any? { try? JSONEncoder().encode(self) }
    @inlinable static func readout(_ data: Any) -> Self? {
        if let raw = data as? Data{
            return try? JSONDecoder().decode(Self.self, from: raw)
        }
        return nil
    }
}
