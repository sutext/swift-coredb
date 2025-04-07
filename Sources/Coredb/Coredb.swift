//
//  Storage.swift
//  swift-coredb
//
//  Created by supertext on 2024/3/15.
//
@_exported import Promise

@preconcurrency import CoreData

/// `Coredb` is built on top of `CoreData`.
/// The main purpose is to apply `CoreData` more safely and conveniently
/// User should inherit from this class for custom configuration and extensions。
///
/// - Important:All managed object `codegen` must be set to `Manual/None`
///
open class Coredb:@unchecked Sendable{
    let moc:NSManagedObjectContext
    private let psc:NSPersistentStoreCoordinator
    private var store:NSPersistentStore!
    public let name:String
    public init(model name:String,bundle:Bundle = .main) throws {
        guard let url = bundle.url(forResource: name, withExtension: "momd") else{
            throw Error.modelNotFound
        }
        guard let modle = NSManagedObjectModel(contentsOf: url) else{
            throw Error.modelNotFound
        }
        self.name = name
        self.psc = NSPersistentStoreCoordinator(managedObjectModel: modle)
        self.moc = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        self.store = try self.addStore()
        self.moc.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        self.moc.persistentStoreCoordinator = psc
    }
    /// default data store url
    open var storeURL:URL{
        let docDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first ?? NSTemporaryDirectory()
        return URL(fileURLWithPath:"\(docDir)/\(name).db")
    }
    /// override this method for custom Persistent Store configure
    ///
    /// - Note: By default use `DocumentDirectory` for dataStore.
    /// - Note: By default use `NSMigratePersistentStoresAutomaticallyOption` and `NSInferMappingModelAutomaticallyOption` options
    ///
    /// - Important: This method will fallback and restore when persistent store auto migration failed. If you don't want to do that, override for custom
    ///
    open func addStore() throws ->NSPersistentStore{
        let options = [
            NSMigratePersistentStoresAutomaticallyOption: true,
            NSInferMappingModelAutomaticallyOption: true
        ]
        do {
            if #available(iOS 15.0,macOS 12.0,tvOS 15.0, watchOS 8.0, *) {
                return try psc.addPersistentStore(type: .sqlite, at: storeURL,options: options)
            }else{
                return try psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: options)
            }
        } catch {
            let error = error as NSError
            if error.code == 134140{ //Persistent store migration failed,missing mapping model.
                print("⚠️Persistent store migration failed.")
            }
            print("⚠️ Add Persistent store failed:",error.domain,"code:",error.code)
            print("⚠️ Restore database !!! All data will be lose")
            // Fallback on Persistent store migration failed
            try FileManager.default.removeItem(at: storeURL)
            if #available(iOS 15.0,macOS 12.0,tvOS 15.0, watchOS 8.0,*) {
                return try psc.addPersistentStore(type: .sqlite, at: storeURL,options: options)
            }else{
                return try psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: options)
            }
        }
    }
    /// Override this method for custom logger
    open func print(_ items:Any... ,line:Int = #line ,file:String = #file){
        Swift.print("line:\(line)","file:\(file)",items,separator: "|")
    }
}
//MARK: public methods
extension Coredb{
    /// save context
    @discardableResult
    public func save() -> Promise<Void> {
        Promise{resolve,reject in
            self.moc.perform {
                do{
                    try self._save()
                    resolve(())
                }catch{
                    reject(error)
                }
            }
        }
    }
    /// flush some entity and save context
    @discardableResult
    public func save<E:Entityable>(_ entity:E)->Promise<Void>{
        Promise{resolve,reject in
            self.moc.perform {
                do{
                    try self._flush(entity)
                    try self._save()
                    resolve(())
                }catch{
                    reject(error)
                }
            }
        }
    }
    /// flush some entities and save context
    @discardableResult
    public func save<E:Entityable>(_ entities:[E])->Promise<Void>{
        Promise{resolve,reject in
            self.moc.perform {
                do{
                    try entities.forEach { obj in
                       try self._flush(obj)
                    }
                    try self._save()
                    resolve(())
                }catch{
                    reject(error)
                }
            }
        }
    }
    /// flush some entity but not save context
    @discardableResult
    public func flush<E:Entityable>(_ entity:E)->Promise<Void>{
        Promise{resolve,reject in
            self.moc.perform {
                do{
                    try self._flush(entity)
                    resolve(())
                }catch{
                    reject(error)
                }
            }
        }
    }
    /// flush some entities but not save context
    @discardableResult
    public func flush<E:Entityable>(_ entities:[E])->Promise<Void>{
        Promise{resolve,reject in
            self.moc.perform {
                do{
                    try entities.forEach { obj in
                       try self._flush(obj)
                    }
                    resolve(())
                }catch{
                    reject(error)
                }
            }
        }
    }
    ///
    /// Delete a managed object from database.
    /// - Parameters:
    ///     - entity: The instance that will be delete
    /// - Returns: `Promise` handler for next async or sync opration
    /// - Note: This method will all auto save context
    @discardableResult
    public func delete<E:Entityable>(_ entity:E)->Promise<Void>{
        guard let entity = entity.reffer else {
            return .init(())//Nothing happend, regard as success
        }
        return Promise{resolve,reject in
            self.moc.perform {
                do{
                    self.moc.delete(entity)
                    try self._save()
                    resolve(())
                }catch{
                    reject(error)
                }
            }
        }
    }
    ///
    /// Delete a managed object from database.
    /// - Parameters:
    ///     - entities: The instance array that will be delete
    /// - Returns: `Promise` handler for next async or sync opration
    /// - Note: This method will all auto save context
    @discardableResult
    public func delete<E:Entityable>(_ entities:[E]) -> Promise<Void> {
        let objects = entities.compactMap{ $0.reffer }
        if objects.isEmpty{
            return .init(())// Nothing happend, regard as success
        }
        return Promise{resolve,reject in
            self.moc.perform {
                do{
                    objects.forEach { self.moc.delete($0) }
                    try self._save()
                    resolve(())
                }catch{
                    reject(error)
                }
            }
        }
    }
    ///
    ///  Insert or update a managed object from model
    /// - Parameters:
    ///     - type: An `Entityable` subclass type
    ///     - input: The data source model instance
    /// - Returns: `Promise` handler for next async or sync opration
    /// - Note: This method will all auto save context
    @discardableResult
    public func insert<E:Entityable>(_ type:E.Type = E.self,input:E.Input)->Promise<E>{
        Promise{resolve,reject in
            self.moc.perform {
                do{
                    let obj = type.init(input)
                    try self._flush(obj)
                    try self._save()
                    resolve(obj)
                }catch{
                    reject(error)
                }
            }
        }
    }
    ///
    ///  Insert or update a group of managed object from models
    /// - Parameters:
    ///    - type: An `Entityable` subclass type
    ///    - inputs: The data source model instance list
    ///    - orderby: An array of`NSSortDescriptor` using result sorts
    /// - Returns: `Promise` handler for next async or sync opration
    /// - Note: This method will all auto save context
    ///
    @discardableResult
    public func insert<E:Entityable>(_ type:E.Type = E.self,inputs:[E.Input],orderby:Orderby? = nil) ->Promise<[E]>{
        Promise{resolve,reject in
            self.moc.perform {
                do{
                    let results = try self._flush(type, inputs:inputs,orderby: orderby)
                    try self._save()
                    resolve(results)
                }catch{
                    reject(error)
                }
            }
        }
    }

    ///
    ///  Query a managed object form id
    /// - Parameters:
    ///     - type: An `Entityable` subclass type
    ///     - id: The object primary id
    /// - Returns: `Promise` handler for next async or sync opration
    /// - Note: This method will all auto save context
    ///
    public func query<E:Entityable>(one type:E.Type = E.self,id:E.ID) -> Promise<E>{
        Promise{resolve,reject in
            self.moc.perform {
                do{
                    resolve(try self._query(one: type, id: id))
                }catch{
                    reject(error)
                }
            }
        }
    }
    ///
    ///  Query all managed entities which match the predicate
    /// - Parameters:
    ///     - type: An `Entityable` subclass type
    ///     - where: The querey predicate
    ///     - page: The pageable query parameters
    ///     - orderby: An `NSSortDescriptor` array . just like order by
    /// - Returns: `Promise` handler for next async or sync opration
    /// - Note: This method will all auto save context
    ///
    public func query<E:Entityable>(_ type:E.Type = E.self,where:Where?=nil,page:Pager?=nil,orderby:Orderby? = nil) -> Promise<[E]>{
        Promise{resolve,reject in
            self.moc.perform {
                do{
                    resolve(try self._query(type, where: `where`, page: page, orderby: orderby))
                }catch{
                    reject(error)
                }
            }
        }
    }
    ///
    ///  Query the count of entities that matching the predicate
    /// - Parameters:
    ///     - type: An `Entityable` subclass type
    ///     - where: The querey predicate
    /// - Returns: `Promise` handler for next async or sync opration
    /// - Note: This method will all auto save context
    ///
    public func count<E:Entityable>(for type:E.Type = E.self,where:Where?=nil)->Promise<Int>{
        Promise{resolve,reject in
            self.moc.perform {
                do{
                    resolve(try self._count(for: type,where: `where`))
                }catch{
                    reject(error)
                }
            }
        }
    }
    /// overlay all the object of the `Entityable` Type
    /// Unlike insert , This method will remove all the object which not exsit in the `models`
    ///
    /// - Parameters:
    ///    - type: type of `Entityable`
    ///    - inputs: source models that need to been insert
    ///    - where: the qurey condition tha will been overlay
    ///    - orderby: An `NSSortDescriptor`  for result  sort
    /// - Returns: `Promise` handler for next async or sync opration
    /// - Note: This method will all auto save context
    ///
    @discardableResult
    public func overlay<E:Entityable>(_ type:E.Type = E.self,inputs:[E.Input],where:Where? = nil,orderby:Orderby? = nil)->Promise<[E]>{
        Promise{resolve,reject in
            self.moc.perform {
                do{
                    let results = try self._overlay(type, inputs: inputs,where: `where`,orderby: orderby)
                    try self._save()
                    resolve(results)
                }catch{
                    reject(error)
                }
            }
        }
    }
}

//MARK: batch update methods. All of them perform I/O operations directly! Never use caches
extension Coredb{
    ///
    /// Batch insert a list of objects
    /// - Parameters:
    ///    - type: An `Entityable` subclass type
    ///    - inputs: The data source model instance list
    /// - Returns: `Promise` handler for next async or sync opration
    /// - Note: This method will all auto save context
    /// - Warning: In this case, there is no need to follow the `Entityable` protocol and no rearrangement mechanism is triggered
    /// - Warning: This method will perform sqlite io directly. Do't around by update(save:closure:) or commit(closure:)
    ///
    @discardableResult
    public func insert<E:Entityable>(_ type:E.Type = E.self,inputs:[[String:Sendable]])->Promise<[E]>{
        Promise{resolve,reject in
            self.moc.perform {
                do{
                    let results = try self._insert(type, inputs: inputs)
                    try self._save()
                    resolve(results)
                }catch{
                    reject(error)
                }
            }
        }
    }
    /// Same as  `insert(_:inputs:)` but `return Void`
    /// - SeeAlso: `insert(_:inputs:)`
    @discardableResult
    public func insert0<E:Entityable>(_ type:E.Type = E.self,inputs:[[String:Sendable]])->Promise<Void>{
        Promise{resolve,reject in
            self.moc.perform {
                do{
                    try self._insert0(type, inputs: inputs)
                    try self._save()
                    resolve(())
                }catch{
                    reject(error)
                }
            }
        }
    }
    /// Same as  `insert(_:inputs:)` but `return ids`
    /// - SeeAlso: `insert(_:inputs:)`
    @discardableResult
    public func insert1<E:Entityable>(_ type:E.Type = E.self,inputs:[[String:Sendable]])-> Promise<[NSManagedObjectID]>{
        Promise{resolve,reject in
            self.moc.perform {
                do{
                    let ids = try self._insert1(type, inputs: inputs)
                    try self._save()
                    resolve(ids)
                }catch{
                    reject(error)
                }
            }
        }
    }
    ///
    /// Batch delete some entities of `type` when predicate.
    /// - Parameters:
    ///    - type:special object type
    ///    - where: The predicate type that will be delete
    /// - Warning: This method will perform sqlite io directly. Do't around by update(save:closure:) or commit(closure:)
    ///
    @discardableResult
    public func delete<E:Entityable>(_ type:E.Type = E.self,where:Where? = nil)-> Promise<[NSManagedObjectID]>{
        Promise{resolve,reject in
            self.moc.perform {
                do{
                    let ids = try self._delete(type, where: `where`)
                    try self._save()
                    resolve(ids)
                }catch{
                    reject(error)
                }
            }
        }
    }
    ///
    /// Batch update some entities of `type` when predicate
    /// - Parameters:
    ///    - type:special object type
    ///    - set: the values to be update
    ///    - where: The predicate type that will be delete
    /// - Warning: This method will perform sqlite io directly. Do't around by update(save:closure:) or commit(closure:)
    ///
    @discardableResult
    public func update<E:Entityable>(_ type:E.Type = E.self,set:[String:Sendable],where:Where? = nil)->Promise<Void>{
        Promise{resolve,reject in
            self.moc.perform {
                do{
                    try self._update(type, set: set, where: `where`)
                    try self._save()
                }catch{
                    reject(error)
                }
            }
        }
    }
}
extension Coredb{
    public enum Error:Swift.Error{
        case modelNotFound
        case entityNotFound
        case objectNotExsit(id:String)
        case invalidEntityID
    }
}
