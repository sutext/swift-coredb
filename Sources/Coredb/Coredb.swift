//
//  Storage.swift
//  swift-coredb
//
//  Created by supertext on 2024/3/15.
//

@preconcurrency import CoreData
@_exported import Promise

public enum CoredbError:Error{
    case invalidID
    case modelNotFound
    case entityNotFound
}

/// global stoage configure
/// User can inherit from this class for custom and extensions。
open class Coredb:@unchecked Sendable{
    let moc:NSManagedObjectContext
    let modelName:String
    public init(model name:String,bundle:Bundle = .main)throws{
        guard let url = bundle.url(forResource: name, withExtension: "momd") else{
            throw CoredbError.modelNotFound
        }
        guard let modle = NSManagedObjectModel(contentsOf: url) else{
            throw CoredbError.modelNotFound
        }
        self.modelName = name
        let psc = NSPersistentStoreCoordinator(managedObjectModel: modle)
        self.moc = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        self.moc.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        let storeURL = URL(fileURLWithPath:"\(databaseDirectory)/\(modelName).db");
        let opions = [
            NSMigratePersistentStoresAutomaticallyOption: true,
            NSInferMappingModelAutomaticallyOption: true
        ]
        do {
            try psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: opions)
        }catch{
            print("⚠️ Add psc error:",error,"restore")
            try FileManager.default.removeItem(at: storeURL);
            try psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: opions)
        }
        self.configure(for: modle)
        self.configure(for: psc)
        self.configure(for: moc)
        self.moc.persistentStoreCoordinator = psc
    }
    /// by default use documentDirectory
    open var databaseDirectory:String{
        NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first ?? NSTemporaryDirectory()
    }
    /// Override this method for custom NSPersistentStoreCoordinator
    open func configure(for psc:NSPersistentStoreCoordinator){
        
    }
    open func configure(for mod:NSManagedObjectModel){
        
    }
    open func configure(for moc:NSManagedObjectContext){
        
    }
    /// Override this method for custom logger
    open func print(_ items:Any... ,line:Int = #line ,file:String = #file){
        Swift.print("line:\(line)","file:\(file)",items,separator: "|")
    }
    /// Automatically submit transaction updates and roll back in case of failure.
    ///
    ///         orm.transaction{handler in
    ///             handler.moc.fetch(...)
    ///             handler.moc.count(...)
    ///             handler.delete(...)
    ///             try handler.overlay(...)
    ///             try handler.create(...)
    ///         }
    ///
    @discardableResult
    public func transaction<T:Sendable>(_ block: @Sendable @escaping (Handler) throws -> T)->Promise<T>{
        Promise{resolve,reject in
            self.moc.perform {
                do{
                    let result = try block(Handler(self))
                    if self.moc.hasChanges{
                        try self.moc.save()
                    }
                    resolve(result)
                }catch{
                    reject(error)
                }
            }
        }
        
    }
}
//MARK: public sync methods
extension Coredb{
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
    @discardableResult
    public func flush<E:Entityable>(_ entity:E,save:Bool = true)->Promise<Void>{
        Promise{resolve,reject in
            self.moc.perform {
                do{
                    try self._flush(entity)
                    if save{
                        try self._save()
                    }
                    resolve(())
                }catch{
                    reject(error)
                }
            }
        }
    }
    @discardableResult
    public func flush<E:Entityable>(_ entities:[E],save:Bool = true)->Promise<Void>{
        Promise{resolve,reject in
            self.moc.perform {
                do{
                    try entities.forEach { obj in
                       try self._flush(obj)
                    }
                    if save{
                        try self._save()
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
    ///     - object: The instance that will be delete
    /// - Warning: This method must be around by update(save:closure:)
    ///
    @discardableResult
    public func delete<E:Entityable>(_ entity:E?)->Promise<Void>{
        guard let entity = entity?.reffer else {
            return .init()
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
    /// - Warning: This method must be around by update(save:closure:)
    ///
    @discardableResult
    public func delete<E:Entityable>(_ entities:[E]?) -> Promise<Void> {
        guard let entities else {
            return .init()
        }
        return Promise{resolve,reject in
            self.moc.perform {
                do{
                    entities.forEach {
                        if let reffer = $0.reffer{
                            self.moc.delete(reffer)
                        }
                    }
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
    ///     - model: The data source model instance
    /// - Throws: some system error from moc.
    /// - Returns: A newly or updated managed object instance
    /// - Important: This method will perform in moc queue
    /// - Important: This method will all auto save context
    ///
    @discardableResult
    public func insert<E:Entityable>(_ type:E.Type,input:E.Input)->Promise<E>{
        Promise{resolve,reject in
            self.moc.perform {
                do{
                    let obj = type.init()
                    try obj.awake(from: input)
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
    ///    - models: The data source model instance list
    ///    - sorts: An array of`NSSortDescriptor` using result sorts
    /// - Throws: some system error from moc.
    /// - Returns: A newly or updated managed object instance list
    /// - Important: This method will perform in moc queue
    /// - Important: This method will all auto save context
    ///
    @discardableResult
    public func insert<E:Entityable>(
        _ type:E.Type,
        inputs:[E.Input],
        orderby:Orderby? = nil) ->Promise<[E]>
    {
        Promise{resolve,reject in
            self.moc.perform {
                do{
                    let results = try self._create(type, inputs:inputs,orderby: orderby)
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
    /// - Returns: The managed object  if matching the id
    /// - Important: This method will perform in moc queue
    ///
    public func query<E:Entityable>(one type:E.Type = E.self,id:E.ID) -> Promise<E?>{
        Promise{resolve,reject in
            self.moc.perform {
                do{
                    let result = try self._query(one: type, id: id)
                    try self._save()
                    resolve(result)
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
    ///     - predicate: The querey predicate
    ///     - page: The pageable query parameters
    ///     - sorts: An `NSSortDescriptor` array . just like order by
    /// - Returns: The managed entities matching the predicate
    /// - Important: This method will perform in moc queue
    ///
    public func query<E:Entityable>(
        _ type:E.Type,
        where:Where?=nil,
        page:Pager?=nil,
        orderby:Orderby? = nil) -> Promise<[E]>
    {
        Promise{resolve,reject in
            self.moc.perform {
                do{
                    let results = try self._query(type, where: `where`, page: page, orderby: orderby)
                    try self._save()
                    resolve(results)
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
    ///     - predicate: The querey predicate
    /// - Returns: The managed entities count that matching the predicate
    /// - Important: This method will perform in moc queue
    ///
    public func count<E:Entityable>(for type:E.Type = E.self,where:Where?=nil)->Promise<Int>{
        Promise{resolve,reject in
            self.moc.perform {
                do{
                    let count = try self._count(for: type,where: `where`)
                    try self._save()
                    resolve(count)
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
    ///    - models: source models that need to been insert
    ///    - where: the qurey condition tha will been overlay
    ///    - sorts: An `NSSortDescriptor`  for result  sort
    /// - Throws: Some error from moc or id not exsit
    /// - Returns: The result object list
    /// - Important: This method will perform in moc queue
    /// - Important: This method will all auto save context
    ///
    @discardableResult
    public func overlay<E:Entityable>(
        _ type:E.Type = E.self,
        inputs:[E.Input],
        where:Where? = nil,
        orderby:Orderby? = nil)->Promise<[E]>
    {
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
    /// - Throws: some system error from moc.
    /// - Returns: A list of new entities
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
    /// `return Void`
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
    /// `retrun ids`
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
    ///    - predicate: The predicate type that will be delete
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
    ///    - predicate: The predicate type that will be delete
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


@globalActor public final actor DataActor{
    public static let shared = DataActor()
}
