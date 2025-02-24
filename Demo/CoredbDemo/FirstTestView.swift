//
//  FirstTestView.swift
//  CoredbDemo
//
//  Created by supertext on 2024/3/19.
//

import SwiftUI
import Combine
import Coredb

struct ItemView:View {
    @StateObject var model:UserObject
    var body: some View {
        VStack(alignment: .leading){
            Text("id:\(model.id)")
            Text("name:\(model.name ?? "")")
            Text("age:\(model.age)")
            Text("gender:\(model.gender ?? .boy)")
            Text("school:\(model.school?.name ?? "")")
            Text("schools count:\(model.schools.count)")
            Button (action:modify){
                Text("修改名字")
            }
        }
    }
    func modify(){
        print(model.schools)
        self.model.name = "Jack \(Int.random(in: 100000...999999))"
        orm.flush(model)
    }
}
struct FirstTestView: View ,Sendable{
    @State var models:[UserObject] = []
    var body: some View {
        NavigationView {
//            Table(models){
//                TableColumn("title"){ m in
//                    ItemView(model: m)
//                }
//            }
            List(models){m in
                ItemView(model: m)
            }
            .toolbar(content: {
                ToolbarItem(placement: .principal) { // 主标题
                    Text("标题")
                }
                ToolbarItemGroup(placement: .navigationBarLeading) { // 右侧工具栏项
                    Button(action: addData) {
                        Text("添加数据")
                    }
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) { // 右侧工具栏项
                    Button(action: modifyData) {
                        Text("修改数据")
                    }
                }
            })
        }
        .onAppear {
            orm.query(UserObject.self,where:.init(format: "id=%@", "")).then { ms in
                await update(ms)
            }
        }
    }
    func update(_ modles:[UserObject]){
        self.models = models
    }
    func addData(){
        let u = UserObject()
        try? u.awake(from: randomUser())
        orm.flush(u)
        self.models.append(u)
        let user = self.randomUser()
        orm.insert(UserObject.self, input: user).then { user in
            await append(user)
        }
        
    }
    func append(_ user:UserObject){

    }
    func modifyData(){
        
    }
    func randomUser()->[String:Sendable&Codable]{
        let id = Int.random(in: 0...10000)
        return [
            "id":"\(id)",
            "gender":id%2,
            "name":"Jack \(id)",
            "classmates":["xiaoming","xiaohong","xiaoli"],
            "school":[
                "name":"紫藤小学",
                "address":"高新区"
            ],
            "schools":[
                ["name":"紫藤小学","address":"高新区"],
                ["name":"西川小学","address":"武侯区"]
            ]
        ]
    }
}
