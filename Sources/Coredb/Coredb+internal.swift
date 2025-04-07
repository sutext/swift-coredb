//
//  Storage+internal.swift
//  swift-coredb
//
//  Created by supertext on 2024/3/15.
//

import Foundation
import CoreData


/// All private method must be call the moc queue
extension Coredb{
    func _save() throws{
        do {
            guard self.moc.hasChanges else{
                return
            }
            try self.moc.save()
        } catch {
            print("Context: \(self.moc) save error:\(error), rollback!")
            self.moc.rollback()
            throw error
        }
    }
    func _query<E:Entityable>(one type:E.Type,id:E.ID)throws->E{
        if id.string.isEmpty{
            throw Error.invalidEntityID
        }
        let request = type.fetchRequest()
        request.predicate = NSPredicate(format:"id == %@",id.string)
        request.fetchLimit = 1
        let objs = try self.moc.fetch(request)
        guard let obj = objs.first else{
            throw Error.objectNotExsit(id:id.string)
        }
        let result = type.init(nil)
        result.attach(obj)
        return result
    }
    func _query<E:Entityable>(
        _ type:E.Type,
        where:Where?,
        page:Pager?,
        orderby:Orderby?)throws->[E]
    {
        let request = type.fetchRequest()
        request.predicate = `where`?.predicate
        request.sortDescriptors = orderby?.sorts
        if let page = page {
            request.fetchLimit = page.size
            request.fetchOffset = page.index * page.size
        }
        let objs =  try self.moc.fetch(request)
        return objs.compactMap{
            let result = type.init(nil)
            result.attach($0)
            return result
        }
    }
    func _overlay<E:Entityable>(
        _ type:E.Type,
        inputs:[E.Input],
        where:Where?,
        orderby:Orderby?) throws -> [E]
    {
        let olds = try self._query(type, where: `where`,page: nil,orderby: nil)
        let results = try self._flush(type, inputs:inputs,orderby: orderby)
        var rms = [E]()
        olds.forEach{ old in
            if !results.contains(where: { $0.id == old.id }){
                rms.append(old)
            }
        }
        rms.forEach {
            if let reffer = $0.reffer{
                self.moc.delete(reffer)
            }
        }        
        return results
    }
    func _update<E:Entityable>(_ type:E.Type,set:[String:Any],where:Where?)throws {
        let entity = try type.entity(in: self.moc)
        let req = NSBatchUpdateRequest(entity: entity)
        req.propertiesToUpdate = set
        req.predicate = `where`?.predicate
        req.resultType = .updatedObjectIDsResultType
        let results = try self.moc.execute(req)
        if let ids = (results as? NSBatchUpdateResult)?.result as? [NSManagedObjectID]{
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: [NSUpdatedObjectIDsKey:ids], into: [self.moc])
        }
    }
    func _delete<E:Entityable>(_ type:E.Type,where:Where?)throws ->[NSManagedObjectID] {
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: type.entityName)
        fetch.predicate = `where`?.predicate
        let req = NSBatchDeleteRequest(fetchRequest: fetch)
        req.resultType = .resultTypeObjectIDs
        let results = try self.moc.execute(req)
        if let ids = (results as? NSBatchDeleteResult)?.result as? [NSManagedObjectID]{
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: [NSDeletedObjectIDsKey:ids], into: [self.moc])
            return ids
        }
        return []
    }
    @discardableResult
    func _insert<E:Entityable>(_ type:E.Type,inputs:[[String:Any]])throws -> [E] {
        let entity = try type.entity(in: self.moc)
        let req = NSBatchInsertRequest(entity: entity, objects: inputs)
        req.resultType = .objectIDs
        let results = try self.moc.execute(req)
        if let ids = (results as? NSBatchInsertResult)?.result as? [NSManagedObjectID]{
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: [NSInsertedObjectIDsKey:ids], into: [self.moc])
            return ids.compactMap {
                let result = type.init(nil)
                result.attach(self.moc.object(with: $0))
                return result
            }
        }
        return []
    }
    func _insert0<E:Entityable>(_ type:E.Type,inputs:[[String:Any]])throws  {
        let entity = try type.entity(in: self.moc)
        let req = NSBatchInsertRequest(entity: entity, objects: inputs)
        req.resultType = .count
        try self.moc.execute(req)
    }
    @discardableResult
    func _insert1<E:Entityable>(_ type:E.Type,inputs:[[String:Any]])throws -> [NSManagedObjectID] {
        let entity = try type.entity(in: self.moc)
        let req = NSBatchInsertRequest(entity: entity, objects: inputs)
        req.resultType = .objectIDs
        let results = try self.moc.execute(req)
        if let ids = (results as? NSBatchInsertResult)?.result as? [NSManagedObjectID]{
            return ids
        }
        return []
    }
    func _flush<E:Entityable>(_ type:E.Type,inputs:[E.Input],orderby: Orderby?)throws->[E]{
        let set:NSMutableOrderedSet = []
        for input in inputs {
            let obj = type.init(input)
            try self._flush(obj)
            set.add(obj)
        }
        if let sorts = orderby?.sorts{
            return (set.sortedArray(using: sorts) as? [E]) ?? []
        }
        return (set.array as? [E]) ?? []
    }
    func _flush<E:Entityable>(_ entity:E) throws{
        if entity.id.string.isEmpty {
            throw Error.invalidEntityID
        }
        if entity.reffer  == nil{
            let request = E.fetchRequest()
            request.predicate = NSPredicate(format:"id == %@",entity.id.string)
            request.fetchLimit = 1
            let mobj = (try? self.moc.fetch(request).first) ?? NSEntityDescription.insertNewObject(forEntityName: E.entityName, into: self.moc)
            entity.attach(mobj)
        }
        entity._flush()
    }
    func _count<E:Entityable>(for type:E.Type,where:Where?)throws -> Int{
        let request = type.fetchRequest()
        request.predicate = `where`?.predicate
        request.resultType = .countResultType
        return try self.moc.count(for: request)
    }
}
extension Coredb{
    public struct Orderby:Sendable{
        public typealias Element = (key:String,ascending:Bool)
        public var elements:[Element]
        public init(_ key: String, ascending: Bool) {
            self.elements = [(key,ascending)]
        }
        public init(_ elements:Element...){
            self.elements = elements
        }
        public static func ascending(_ key:String)->Orderby{
            .init(key, ascending: true)
        }
        public static func descending(_ key:String)->Orderby{
            .init(key, ascending: false)
        }
        public var sorts:[NSSortDescriptor]{
            self.elements.map{
                .init(key: $0.key, ascending: $0.ascending)
            }
        }
    }
    public struct Pager:Sendable{
        public var index:Int ///page index
        public var size:Int /// page size
        public init(index: Int, size: Int) {
            self.index = index
            self.size = size
        }
    }
    public struct Where:Sendable{
        public var format:String
        public var args:[Sendable]
        public init(_ format: String, _ args: Sendable...) {
            self.format = format
            self.args = args
        }
        public var predicate:NSPredicate{
            .init(format: format, argumentArray: args)
        }
    }
}
