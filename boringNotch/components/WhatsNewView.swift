//
//  WhatsNewView.swift
//  boringNotch
//
//  Created by Richard Kunkli on 09/08/2024.
//

import SwiftUI

struct WhatsNewView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Text("本版更新")
                .font(.largeTitle)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("• 设置页和常用弹窗继续中文化")
                Text("• 优化中国用户的媒体来源和文件分享说明")
                Text("• 修复已知体验问题")
            }
            
            Button("知道了") {
                isPresented = false
            }
        }
        .frame(width: 300, height: 200)
        .padding()
    }
}

#Preview {
    WhatsNewView(isPresented: .constant(true))
}
