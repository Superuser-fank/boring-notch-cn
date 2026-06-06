//
//  generic.swift
//  boringNotch
//
//  Created by Harsh Vardhan  Goswami  on 04/08/24.
//

import Foundation
import Defaults

public enum Style {
    case notch
    case floating
}

public enum ContentType: Int, Codable, Hashable, Equatable {
    case normal
    case menu
    case settings
}

public enum NotchState {
    case closed
    case open
}

public enum NotchViews {
    case home
    case shelf
}

enum SettingsEnum {
    case general
    case about
    case charge
    case download
    case mediaPlayback
    case hud
    case shelf
    case extensions
}

enum DownloadIndicatorStyle: String, Defaults.Serializable {
    case progress = "Progress"
    case percentage = "Percentage"

    var displayName: String {
        switch self {
        case .progress:
            "进度条"
        case .percentage:
            "百分比"
        }
    }
}

enum DownloadIconStyle: String, Defaults.Serializable {
    case onlyAppIcon = "Only app icon"
    case onlyIcon = "Only download icon"
    case iconAndAppIcon = "Icon and app icon"

    var displayName: String {
        switch self {
        case .onlyAppIcon:
            "仅显示应用图标"
        case .onlyIcon:
            "仅显示下载图标"
        case .iconAndAppIcon:
            "应用图标和下载图标"
        }
    }
}

enum MirrorShapeEnum: String, Defaults.Serializable {
    case rectangle = "Rectangular"
    case circle = "Circular"

    var displayName: String {
        switch self {
        case .rectangle:
            "方形"
        case .circle:
            "圆形"
        }
    }
}

enum WindowHeightMode: String, Defaults.Serializable {
    case matchMenuBar = "Match menubar height"
    case matchRealNotchSize = "Match real notch height"
    case custom = "Custom height"

    var displayName: String {
        switch self {
        case .matchMenuBar:
            "匹配菜单栏高度"
        case .matchRealNotchSize:
            "匹配真实刘海高度"
        case .custom:
            "自定义高度"
        }
    }
}

enum SliderColorEnum: String, CaseIterable, Defaults.Serializable {
    case white = "White"
    case albumArt = "Match album art"
    case accent = "Accent color"

    var displayName: String {
        switch self {
        case .white:
            "白色"
        case .albumArt:
            "匹配专辑封面"
        case .accent:
            "强调色"
        }
    }
}
