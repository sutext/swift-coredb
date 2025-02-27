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
            Text("weight:\(model.weight)")
            Text("gender:\(model.gender ?? .boy)")
            Text("working:\(model.working?.description ?? "")")
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
            Table(models){
                TableColumn("title"){ m in
                    ItemView(model: m)
                }
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
                    Button(action: clearData) {
                        Text("清除数据")
                    }
                }
            })
        }
        .onAppear {
            orm.query(UserObject.self,where: .init("age>%@", 0),orderby: .ascending("id")).then { ms in
                await update(ms)
            }
        }
    }
    func update(_ ms:[UserObject]){
        self.models = ms
    }
    func addData(){
        let u = UserObject(randomUser())
        orm.flush(u).then { _ in
            await append(u)
        }
        let user = self.randomUser()
        orm.insert(UserObject.self, input: user).then { user in
            await append(user)
        }.catch { err in
            await alert(err)
        }
    }
    func alert(_ error:Error){
        
    }
    func append(_ user:UserObject){
        self.models.insert(user, at: 0)
    }
    func clearData(){
        orm.delete(self.models).then { _ in
            await update([])
        }
    }
    func randomUser()->[String:Sendable]{
        let id = Int.random(in: 0...10000)
        let working:[String:Sendable] = [
            "name":"腾讯科技",
            "school":[
                "name":"腾讯老年大学"
            ]
        ]
        return [
            "id":id,
            "age":UInt16.random(in: 0...200),
            "gender":id%2,
            "name":"Jack \(id)",
            "classmates":["xiaoming","xiaohong","xiaoli"],
            "school":[
                "name":"紫藤小学",
                "address":"高新区"
            ],
            "working":working,
            "weight":Int.random(in: 10...100),
            "schools":[
                ["name":"紫藤小学","address":"高新区"],
                ["name":"西川小学","address":"武侯区"]
            ]
        ]
    }
}
