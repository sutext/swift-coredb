//
//  Handler.swift
//  swift-coredb
//
//  Created by supertext on 2024/3/15.
//

import CoreData


/// All the handler methods can will be execute in internal moc queue
/// This is a highly customized interface.  You can do whatever you want
/// All the handler methods never save automatically
extension Coredb{
    public struct Handler:Sendable{
        let storage:Coredb
        init(_ storage:Coredb){
            self.storage = storage
        }
        /// The global ManagedObjectContext
        private var moc:NSManagedObjectContext { storage.moc }
        
        ///@see `Coredb`.insert(type:inputs)
        @discardableResult
        public func insert<E:Entityable>(
            _ type: E.Type,
            inputs: [[String:Any]]) throws ->[E]  {
            try self.storage._insert(type, inputs: inputs)
        }
        public func insert0<E:Entityable>(
            _ type: E.Type,
            inputs: [[String:Any]]) throws  {
            try self.storage._insert0(type, inputs: inputs)
        }
        ///@see `Coredb`.insert0(type:inputs)
        @discardableResult
        public func insert1<E:Entityable>(
            _ type: E.Type,
            inputs: [[String:Any]]) throws ->[NSManagedObjectID]  {
            try self.storage._insert1(type, inputs: inputs)
        }
        ///@see `Coredb`.delete(type:where)
        @discardableResult
        public func delete<E:Entityable>(
            _ type: E.Type,
            where: Where? = nil) throws ->[NSManagedObjectID]  {
            try self.storage._delete(type, where: `where`)
        }
        ///@see `Coredb`.update(type:set:where)
        public func update<E:Entityable>(
            _ type: E.Type,
            set: [String : Any],
            where: Where? = nil)throws{
            try self.storage._update(type, set: set, where: `where`)
        }
        
        ///@see `Coredb`.create
        public func insert<E:Entityable>(
            _ type:E.Type,
            inputs:[E.Input],
            orderby: Orderby? =  nil)throws->[E]{
            try self.storage._flush(type, inputs: inputs,orderby: orderby)
        }
        ///@see `Coredb`.create
        public func insert<E:Entityable>(
            _ type:E.Type,
            input:E.Input)throws->E{
            let obj = type.init(input)
                try self.storage._flush(obj)
            return obj
        }
        ///@see `Coredb`.query(one:id)
        public func query<E:Entityable>(
            one type:E.Type,
            id:E.ID)throws -> E?{
            try self.storage._query(one: type, id: id)
        }
        ///@see `Coredb`.query(type:where)
        public func query<E:Entityable>(
            _ type:E.Type,
            where: Where?  =  nil,
            page: Pager? = nil,
            orderby: Orderby? = nil)throws->[E]{
            try self.storage._query(type,where: `where`,page: page,orderby: orderby)
        }
        ///@see `Coredb`.overlay(type:modles:where)
        @discardableResult
        public func overlay<E:Entityable>(
            _ type:E.Type,inputs:[E.Input],
            where: Where?  = nil,
            orderby: Orderby?  = nil) throws -> [E]{
                try self.storage._overlay(type, inputs: inputs,where: `where`,orderby: orderby)
        }
        ///@see `Coredb`.count
        public func count<E:Entityable>(
            for type: E.Type,
            where: Where? = nil)throws -> Int {
            try self.storage._count(for: type, where: `where`)
        }
    }
}
