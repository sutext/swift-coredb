//
//  FieldProperty.swift
//  swift-coredb
//
//  Created by supertext on 2024/3/22.
//

import Foundation
import Combine
import CoreData

protocol AnyField:AnyObject{
    var target:Entity?{ get set }
    var key:String {get set}
    func flush()
}
extension Entity{
    @propertyWrapper
    public final class Field<T:Fieldable>:@unchecked Sendable{
        public typealias Publisher = CurrentValueSubject<T,Never>
        var value:T
        var key:String = ""
        weak var target:Entity?
        private var hasChange:Bool = false
        private var hasLoaded:Bool = false
        private var publisher:Publisher?
        public init(wrappedValue: T) {
            self.value = wrappedValue
        }
        public var wrappedValue: T{
            get {
                if hasLoaded{
                    return value
                }
                if let raw = self.target?.reffer?.value(forKey: key),
                   let value = T.readout(raw){
                    self.value = value
                    self.hasLoaded = true
                    return value
                }
                return value
            }
            set{
                if value != newValue{
                    value = newValue
                    self.hasChange = true
                    self.hasLoaded = true
                    DispatchQueue.main.async {
                        if let publisher = self.publisher{
                            publisher.send(self.value)
                        }
                        if let obtarget = self.target as? (any ObservableEntity){
                            obtarget.objectWillChange.send()
                        }
                    }
                }
            }
        }
        public var projectedValue:Publisher{
            if let publisher{
                return publisher
            }
            let publisher = Publisher(wrappedValue)
            self.publisher = publisher
            return publisher
        }
        func flush() {
            if self.hasChange, let reffer = self.target?.reffer{
                reffer.setValue(wrappedValue.writein(), forKey: key)
                self.hasChange = false
            }
        }
    }
}

extension Entity.Field:AnyField{}
