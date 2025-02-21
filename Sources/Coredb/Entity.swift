//
//  CoreObject.swift
//  swift-coredb
//
//  Created by supertext on 2024/3/12.
//

import CoreData
import Combine

public protocol EntityID:Codable,Hashable{}

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

open class Entity{
    private(set) var reffer:NSManagedObject?
    private var allFields:[AnyField] = []
    public required init(){
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
//    func reload(){
//        self.allFields.forEach {
//            
//            if let value = self.reffer?.value(forKey: $0.key){
//                $0.value.setValue(value)
//            }
//        }
//    }
    func _flush(){
        self.allFields.forEach {
            $0.flush()
        }
    }
    public var isFault:Bool?{
        self.reffer?.isFault
    }
    public var isDeleted:Bool?{
        self.reffer?.isDeleted
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
/// A convenience initializer is recommended to implement the `init(_:)` method  `eg:`
///
///     class UserObject:Entity,Entityable
///         static var entityName:String = "UserObject"
///         required convenience init(_ model: [AnyHashable : Any]) throws{
///             self.init()
///             self.id = model["id"] as! String
///         }
///     }
///
public protocol Entityable:Entity,Identifiable,Sendable where ID:EntityID{
    associatedtype Input:Sendable
    init()
    /// The model initializer
    func awake(from data:Input)throws
    /// The  entity name  of managed object
    static var entityName:String { get }
}
extension Entityable{
    
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
