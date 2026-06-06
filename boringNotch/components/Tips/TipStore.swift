//
//  TipStore.swift
//  boringNotch
//
//  Created by Richard Kunkli on 15/09/2024.
//

import SwiftUI
import TipKit

struct HUDsTip: Tip {
    var title: Text {
        Text("启用更清晰的 HUD")
    }
    
    
    var message: Text? {
        Text("可以在设置中用自定义样式替换系统音量、亮度和键盘灯提示。")
    }
    
    
    var image: Image? {
        Image(systemName: "dial.medium.fill")
    }
    
    var actions: [Action] {
        Action {
            Text("去设置")
        }
    }
}

struct CBTip: Tip {
    var title: Text {
        Text("用文件架暂存常用内容")
    }
    
    
    var message: Text? {
        Text("把文件或文本拖到刘海区域，可快速暂存、复制或投递到常用国产应用。")
    }
    
    
    var image: Image? {
        Image(systemName: "tray.full.fill")
    }
    
    var actions: [Action] {
        Action {
            Text("了解")
        }
    }
}

struct TipsView: View {
    var hudTip = HUDsTip()
    var cbTip = CBTip()
    var body: some View {
        VStack {
            TipView(hudTip)
            TipView(cbTip)
        }
        .task {
            try? Tips.configure([
                .displayFrequency(.immediate),
                .datastoreLocation(.applicationDefault)
            ])
        }
    }
}

#Preview {
    TipsView()
}
