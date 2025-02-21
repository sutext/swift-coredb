//
//  ContentView.swift
//  CoredbDemo
//
//  Created by supertext on 2024/3/19.
//

import SwiftUI

struct ContentView: View {
    @State private var selection = 0 // 用于跟踪当前选中的标签页索引

    var body: some View {
        TabView(selection: $selection) {
            // 第一个标签页内容
            FirstTestView()
                .tabItem {
                    Image(systemName: "1.circle.fill") // 图标
                    Text("首页") // 标题
                }
            // 第二个标签页内容
            SecondTestView()
                .tabItem {
                    Image(systemName: "2.circle.fill")
                    Text("探索")
                }
            ThirdTestView()
                .tabItem {
                    Image(systemName: "3.circle.fill")
                    Text("发现")
                }
            // 其他标签页...
        }
        .accentColor(.blue) // 设置选中时的颜色（例如文本和图标）
    }
}




#Preview {
    ContentView()
}
