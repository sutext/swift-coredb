//
//  UserObject.swift
//  CoredbDemo
//
//  Created by supertext on 2024/3/19.
//

import Foundation
import Combine
import Coredb


enum Gender:Int,Fieldable{
    case boy = 0
    case girl = 1
}
struct Weight:RawRepresentable,Fieldable{
    let rawValue:Int
    init(rawValue: Int) {
        self.rawValue = rawValue
    }
}
extension Weight:ExpressibleByIntegerLiteral{
    init(integerLiteral value: IntegerLiteralType) {
        self.rawValue = value
    }
}
extension Weight:CustomStringConvertible{
    var description: String{ "\(rawValue)" }
}
class Working:Fieldable,Hashable{
    var name:String = ""
    var type:String = ""
    var school:School? = nil
    func hash(into hasher: inout Hasher) {
        name.hash(into: &hasher)
        type.hash(into: &hasher)
    }
    static func ==(l:Working,r:Working)->Bool{
        l.hashValue == r.hashValue
    }
    init(_ dic:Any?){
        guard let dic = dic as? [AnyHashable:Any] else{
            return
        }
        if let name = dic["name"] as? String{
            self.name = name
        }
        if let addr = dic["type"] as? String{
            self.type = addr
        }
        self.school = School(dic["school"])
    }
}
extension Working:CustomStringConvertible{
    var description: String{
        "working:\(name),school:\(school?.name ?? "")"
    }
}
struct School:Fieldable{
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
}

final class UserObject:Entity, Entityable, ObservableEntity,@unchecked Sendable{    
    @Field var id:Int = 0
    @Field var name:String?
    @Field var age:UInt16 = 0
    @Field var gender:Gender?
    @Field var school:School?
    @Field var schools:[School] = []
    @Field var classmates:[String]?
    @Field var weight:Weight = 0
    @Field var working:Working? = nil
    @Field var parteners:Set<String> = []
    init(_ data: [String:Sendable]? = nil) {
        super.init()
        guard let data else{
            return
        }
        guard let id = data["id"] as? Int else{ // id must contains in data otherwise keep empty
            return
        }
        self.id = id
        self.age = (data["age"] as? UInt16) ?? 0
        self.weight = Weight(rawValue: (data["weight"] as? Int) ?? 0 )
        self.gender = Gender(rawValue: (data["gender"] as? Int) ?? 0) ?? .boy
        self.school = School(data["school"])
        self.name = (data["name"] as? String) ?? ""
        if let ary = data["schools"] as? [Any]{
            self.schools = ary.map{School($0)}
        }
        if let ary = data["classmates"] as? [String]{
            self.classmates = ary
        }
        self.working = Working(data["working"])
        self.parteners = ["gold","silver"]
    }
}
let orm = DataBase()

final class DataBase:Coredb,@unchecked Sendable{
    init(){
        try! super.init(model: "Coredb")
    }
}
