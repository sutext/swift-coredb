//
//  ThirdTestView.swift
//  CoredbDemo
//
//  Created by supertext on 2024/3/19.
//

import SwiftUI

struct ThirdTestView: View {
    var body: some View {
        
        NavigationView {
            Text("主内容区域")
                .navigationBarTitle("标题", displayMode: .inline) // 设置导航栏标题
                .navigationBarItems(leading: HStack { // 左侧项目
                    Button(action: {}) {
                        Image(systemName: "list.bullet")
                    }
                }, trailing: HStack { // 右侧项目
                    Button(action: {}) {
                        Image(systemName: "1.circle.fill")
                    }
                    Button(action: {}) {
                        Image(systemName: "2.circle.fill")
                    }
                })
        }
    }
}
