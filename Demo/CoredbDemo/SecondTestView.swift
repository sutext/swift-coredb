//
//  SecondTestView.swift
//  CoredbDemo
//
//  Created by supertext on 2024/3/19.
//

import SwiftUI

class Inner:ObservableObject,Identifiable{
    @Published var name:String = "inner"
}
class Outer:ObservableObject{
    @Published var inner:Inner = Inner()
    @Published var inners:[Inner] = [Inner(),Inner(),Inner()]
    @Published var name:String
    init(name: String) {
        self.name = name
    }
}

struct SecondTestView: View {
    @StateObject var outer:Outer = Outer(name: "")
    var body: some View {
        NavigationView {
            VStack{
                Text(outer.name)
                
                Color.red.frame(width: 100, height: 200, alignment: .top)
                Button(action:click){
                    Text("点击测试")
                }
                ForEach(outer.inners) { i in
                    HStack{
                        Text(i.name)
                        Button(action:{
                            i.name = "\(Int.random(in: 100000...999999))"
                        }){
                            Text("点击测试")
                        }
                    }
                }
            }
            .padding(.top)
            .toolbar(content: {
                ToolbarItem(placement: .principal) { // 主标题
                    Text("标题")
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) { // 右侧工具栏项
                    Button(action: {}) {
                        Image(systemName: "search")
                    }
                    Button(action: {}) {
                        Label("更多", systemImage: "ellipsis.circle")
                    }
                }
            })
        }
    }
    func click(){
        outer.name = "\(Int.random(in: 100000...999999))"
    }
}
