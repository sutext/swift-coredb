//
//  CoreObject.swift
//  swift-coredb
//
//  Created by supertext on 2024/3/12.
//

import CoreData
import Combine

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
        case let int as Int8:
            return String(int)
        case let int as Int16:
            return String(int)
        case let int as Int32:
            return String(int)
        case let int as Int64:
            return String(int)
        case let int as Int:
            return String(int)
        case let int as UInt64:
            return String(int)
        case let uuid as UUID:
            return uuid.uuidString
        case let str as String:
            return str
        default:
            return ""
        }
    }
}
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
public protocol ObservableEntity:ObservableObject{
    var objectWillChange:ObservableObjectPublisher{ get }
}
/// `Entityable` protocol describe a schema of managed object for orm structure
///
public protocol Entityable:Entity,Identifiable,Sendable where ID:EntityID{
    associatedtype Input:Sendable
    init(_ data:Input?)
    var isEmpty:Bool { get }
    static var entityName:String { get }
}
extension Entityable{
    /// default empty implements
    var isEmpty:Bool { id.string.isEmpty }
    /// default entityName implements
    public static var entityName: String { String(describing: Self.self) }
    static func fetchRequest()->NSFetchRequest<NSManagedObject>{
        NSFetchRequest<NSManagedObject>.init(entityName: entityName)
    }
    static func entity(in context:NSManagedObjectContext)throws -> NSEntityDescription{
        guard let entity = NSEntityDescription.entity(forEntityName: entityName, in: context) else{
            throw CoredbError.entityNotFound
        }
        return entity
    }
}
