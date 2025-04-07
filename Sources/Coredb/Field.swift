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
    var key:String {get set}
    var target:Entity?{ get set }
    func readout()
    func writein()
}
extension Entity{
    @propertyWrapper
    public final class Field<T:Fieldable>:AnyField,@unchecked Sendable{
        public typealias Publisher = CurrentValueSubject<T,Never>
        var value:T
        var key:String = ""
        weak var target:Entity?
        private var loaded:Bool = false
        private var changed:Bool = false
        private var publisher:Publisher?
        public init(wrappedValue: T) {
            self.value = wrappedValue
        }
        public var wrappedValue: T{
            get {
                readout()
                return value
            }
            set{
                if value != newValue{
                    value = newValue
                    self.changed = true
                    self.loaded = true
                    DispatchQueue.main.async {
                        if let publisher = self.publisher{
                            publisher.send(self.value)
                        }
                        if let ob = self.target as? any ObservableEntity{
                            ob.objectWillChange.send()
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
        func readout(){
            if loaded{
                return
            }
            if let raw = self.target?.reffer?.value(forKey: key),
               let value = T.readout(raw){
                self.value = value
                self.loaded = true
            }
        }
        func writein(){
            if changed,let reffer = self.target?.reffer{
                reffer.setValue(wrappedValue.writein(), forKey: key)
                self.changed = false
            }
        }
    }
}
