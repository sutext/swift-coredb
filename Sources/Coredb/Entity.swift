//
//  CoreObject.swift
//  swift-coredb
//
//  Created by supertext on 2024/3/12.
//

import CoreData
import Combine

/// - Important: Do not declare new conformances to this protocol, they will not work as expected.
public protocol EntityID:Codable,Hashable,Sendable{}

extension Int:EntityID{}
extension Int8:EntityID{}
extension Int16:EntityID{}
extension Int32:EntityID{}
extension Int64:EntityID{}
extension UInt:EntityID{}
extension UInt8:EntityID{}
extension UInt16:EntityID{}
extension UInt32:EntityID{}
extension UInt64:EntityID{}
extension String:EntityID{}
extension UUID:EntityID{}
extension EntityID{
    var string:String{
        switch self {
        case let str as String:
            return str
        case let int as any FixedWidthInteger:
            return Int(int) == 0 ? "" : String(int)
        case let uuid as UUID:
            return uuid.uuidString
        default:
            return ""
        }
    }
}

//@attached(member)
//@attached(memberAttribute)
//@attached(extension)
//public macro Entity() = #externalMacro(module: "CoredbPlugin", type: "EntityMacro")

/// This class is the parent class of all managed objects
/// - Important:All managed object `codegen` must be set to `Manual/None`

open class Entity:@unchecked Sendable{
    private(set) var reffer:NSManagedObject?
    private var allFields:[AnyField] = []
    public init() {
        self.allFields = Mirror(reflecting: self).children.compactMap {
            if let field = $0.value as? AnyField{
                if field.key.isEmpty,let label = $0.label{
                    field.key = String(label.dropFirst())
                }
                field.target = self
                return field
            }
            return nil
        }
    }
    func attach(_ reffer:NSManagedObject){
        guard self.reffer == nil else { return }
        self.reffer = reffer
    }
    func _flush(){
        self.allFields.forEach {
            $0.writein()
        }
    }
}
extension Entity:CustomStringConvertible{
    public var description: String{
        "[AllFields]:\n\(allFields)\n[RawObject]:\n:\(reffer==nil ? "nil" : reffer!.description )"
    }
}
/// `ObservableEntity` grant  ability of`@StateObject` an `@State` in `SwiftUI`
///- Note: subclass of `Entity` can implement this protocol for `SwiftUI` usage
public protocol ObservableEntity:Entity,ObservableObject{
    var objectWillChange:ObservableObjectPublisher{ get }
}

/// `Entityable` protocol describe a schema of managed object for orm structure
///- Note: subclass of `Entity` must implement this protocol
/// - Important:All managed object `codegen` must be set to `Manual/None`
///
public protocol Entityable:Entity,Identifiable,Sendable where ID:EntityID{
    associatedtype Input:Sendable
    init(_ data:Input?)
    static var entityName:String { get }
}
/// Add some property and default implemention for `Entityable`
extension Entityable{
    /// default entityName implements
    public static var entityName: String { String(describing: Self.self) }
    /// Determines whether the currently managed object is empty
    /// `""`  of`String` or `0` of `FixedWidthInteger` will be regarded as empty.
    public var isEmpty:Bool { id.string.isEmpty }
    /// internal method for fetch request
    static func fetchRequest()->NSFetchRequest<NSManagedObject>{
        NSFetchRequest<NSManagedObject>.init(entityName: entityName)
    }
    /// internal method of entiity description
    static func entity(in context:NSManagedObjectContext)throws -> NSEntityDescription{
        guard let entity = NSEntityDescription.entity(forEntityName: entityName, in: context) else{
            throw Coredb.Error.entityNotFound
        }
        return entity
    }
}
