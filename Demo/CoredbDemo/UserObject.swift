//
//  UserObject.swift
//  CoredbDemo
//
//  Created by supertext on 2024/3/19.
//

import Foundation
import CoreData
import Combine
import Coredb


enum Gender:Int,Fieldable{
    case boy = 0
    case girl = 1
}

struct School:JSONFieldable{
    var name:String = ""
    var address:String = ""
    init(_ dic:Any?){
        guard let dic = dic as? [AnyHashable:Any] else{
            return
        }
        if let name = dic["name"] as? String{
            self.name = name
        }
        if let addr = dic["address"] as? String{
            self.address = addr
        }
    }
//    @inlinable func writein() -> Any? { try? JSONEncoder().encode(self) }
//    @inlinable static func readout(_ data: Any) -> Self? {
//        if let raw = data as? Data{
//            return try? JSONDecoder().decode(Self.self, from: raw)
//        }
//        return nil
//    }
}

final class UserObject:Entity, Entityable, ObservableEntity,@unchecked Sendable{
    @Field var id:String = ""
    @Field var name:String?
    @Field var age:UInt16 = 0
    @Field var gender:Gender?
    @Field var school:School?
    @Field var schools:[School] = []
    @Field var classmates:[String]?
    func awake(from data: [String:Sendable&Codable]) throws {
        guard let id = data["id"] as? String else{
            throw CoredbError.invalidID
        }
        self.id = id
        self.gender = Gender(rawValue: (data["gender"] as? Int) ?? 0) ?? .boy
        self.school = School(data["school"])
        self.name = (data["name"] as? String) ?? ""
        if let ary = data["schools"] as? [Any]{
            self.schools = ary.map{School($0)}
        }
        if let ary = data["classmates"] as? [String]{
            self.classmates = ary
        }
    }
}
let orm = DataBase()

final class DataBase:Coredb,@unchecked Sendable{
    init(){
        try! super.init(model: "Coredb")
    }
}
