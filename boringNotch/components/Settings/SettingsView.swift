//
//  SettingsView.swift
//  boringNotch
//
//  Created by Richard Kunkli on 07/08/2024.
//

import AppKit
import AVFoundation
import Defaults
import EventKit
import KeyboardShortcuts
import LaunchAtLogin
import Sparkle
import SwiftUI
import SwiftUIIntrospect

struct SettingsView: View {
    @State private var selectedTab = "General"
    @State private var accentColorUpdateTrigger = UUID()

    let updaterController: SPUStandardUpdaterController?

    init(updaterController: SPUStandardUpdaterController? = nil) {
        self.updaterController = updaterController
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedTab) {
                NavigationLink(value: "General") {
                    Label("通用", systemImage: "gear")
                }
                NavigationLink(value: "Appearance") {
                    Label("外观", systemImage: "eye")
                }
                NavigationLink(value: "Media") {
                    Label("媒体", systemImage: "play.laptopcomputer")
                }
                NavigationLink(value: "Calendar") {
                    Label("日历", systemImage: "calendar")
                }
                NavigationLink(value: "HUD") {
                    Label("HUD", systemImage: "dial.medium.fill")
                }
                NavigationLink(value: "Battery") {
                    Label("电池", systemImage: "battery.100.bolt")
                }
//                NavigationLink(value: "Downloads") {
//                    Label("Downloads", systemImage: "square.and.arrow.down")
//                }
                NavigationLink(value: "Shelf") {
                    Label("文件架", systemImage: "books.vertical")
                }
                NavigationLink(value: "Shortcuts") {
                    Label("快捷键", systemImage: "keyboard")
                }
                // NavigationLink(value: "Extensions") {
                //     Label("Extensions", systemImage: "puzzlepiece.extension")
                // }
                NavigationLink(value: "Advanced") {
                    Label("高级", systemImage: "gearshape.2")
                }
                NavigationLink(value: "About") {
                    Label("关于", systemImage: "info.circle")
                }
            }
            .listStyle(SidebarListStyle())
            .tint(.effectiveAccent)
            .toolbar(removing: .sidebarToggle)
            .navigationSplitViewColumnWidth(200)
        } detail: {
            Group {
                switch selectedTab {
                case "General":
                    GeneralSettings()
                case "Appearance":
                    Appearance()
                case "Media":
                    Media()
                case "Calendar":
                    CalendarSettings()
                case "HUD":
                    HUD()
                case "Battery":
                    Charge()
                case "Shelf":
                    Shelf()
                case "Shortcuts":
                    Shortcuts()
                case "Extensions":
                    GeneralSettings()
                case "Advanced":
                    Advanced()
                case "About":
                    About(updaterController: updaterController)
                default:
                    GeneralSettings()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationSplitViewStyle(.balanced)
        .toolbar(removing: .sidebarToggle)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("")
                    .frame(width: 0, height: 0)
                    .accessibilityHidden(true)
            }
        }
        .formStyle(.grouped)
        .frame(width: 700)
        .background(Color(NSColor.windowBackgroundColor))
        .tint(.effectiveAccent)
        .id(accentColorUpdateTrigger)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("AccentColorChanged"))) { _ in
            accentColorUpdateTrigger = UUID()
        }
    }
}

struct GeneralSettings: View {
    @State private var screens: [(uuid: String, name: String)] = NSScreen.screens.compactMap { screen in
        guard let uuid = screen.displayUUID else { return nil }
        return (uuid, screen.localizedName)
    }
    @EnvironmentObject var vm: BoringViewModel
    @ObservedObject var coordinator = BoringViewCoordinator.shared

    @Default(.mirrorShape) var mirrorShape
    @Default(.showEmojis) var showEmojis
    @Default(.gestureSensitivity) var gestureSensitivity
    @Default(.minimumHoverDuration) var minimumHoverDuration
    @Default(.nonNotchHeight) var nonNotchHeight
    @Default(.nonNotchHeightMode) var nonNotchHeightMode
    @Default(.notchHeight) var notchHeight
    @Default(.notchHeightMode) var notchHeightMode
    @Default(.showOnAllDisplays) var showOnAllDisplays
    @Default(.automaticallySwitchDisplay) var automaticallySwitchDisplay
    @Default(.enableGestures) var enableGestures
    @Default(.openNotchOnHover) var openNotchOnHover
    

    var body: some View {
        Form {
            Section {
                Toggle(isOn: Binding(
                    get: { Defaults[.menubarIcon] },
                    set: { Defaults[.menubarIcon] = $0 }
                )) {
                    Text("显示菜单栏图标")
                }
                .tint(.effectiveAccent)
                LaunchAtLogin.Toggle {
                    Text("登录时启动")
                }
                Defaults.Toggle(key: .showOnAllDisplays) {
                    Text("在所有显示器上显示")
                }
                .onChange(of: showOnAllDisplays) {
                    NotificationCenter.default.post(
                        name: Notification.Name.showOnAllDisplaysChanged, object: nil)
                }
                Picker("首选显示器", selection: $coordinator.preferredScreenUUID) {
                    ForEach(screens, id: \.uuid) { screen in
                        Text(screen.name).tag(screen.uuid as String?)
                    }
                }
                .onChange(of: NSScreen.screens) {
                    screens = NSScreen.screens.compactMap { screen in
                        guard let uuid = screen.displayUUID else { return nil }
                        return (uuid, screen.localizedName)
                    }
                }
                .disabled(showOnAllDisplays)
                
                Defaults.Toggle(key: .automaticallySwitchDisplay) {
                    Text("自动切换显示器")
                }
                    .onChange(of: automaticallySwitchDisplay) {
                        NotificationCenter.default.post(
                            name: Notification.Name.automaticallySwitchDisplayChanged, object: nil)
                    }
                    .disabled(showOnAllDisplays)
            } header: {
                Text("系统功能")
            }

            ChinaSetupHelpSection()

            Section {
                Picker(
                    selection: $notchHeightMode,
                    label:
                        Text("刘海屏上的刘海高度")
                ) {
                    Text("匹配真实刘海高度")
                        .tag(WindowHeightMode.matchRealNotchSize)
                    Text("匹配菜单栏高度")
                        .tag(WindowHeightMode.matchMenuBar)
                    Text("自定义高度")
                        .tag(WindowHeightMode.custom)
                }
                .onChange(of: notchHeightMode) {
                    switch notchHeightMode {
                    case .matchRealNotchSize:
                        notchHeight = 38
                    case .matchMenuBar:
                        notchHeight = 44
                    case .custom:
                        notchHeight = 38
                    }
                    NotificationCenter.default.post(
                        name: Notification.Name.notchHeightChanged, object: nil)
                }
                if notchHeightMode == .custom {
                    Slider(value: $notchHeight, in: 15...45, step: 1) {
                        Text("自定义刘海尺寸 - \(notchHeight, specifier: "%.0f")")
                    }
                    .onChange(of: notchHeight) {
                        NotificationCenter.default.post(
                            name: Notification.Name.notchHeightChanged, object: nil)
                    }
                }
                Picker("非刘海屏上的刘海高度", selection: $nonNotchHeightMode) {
                    Text("匹配菜单栏高度")
                        .tag(WindowHeightMode.matchMenuBar)
                    Text("匹配真实刘海高度")
                        .tag(WindowHeightMode.matchRealNotchSize)
                    Text("自定义高度")
                        .tag(WindowHeightMode.custom)
                }
                .onChange(of: nonNotchHeightMode) {
                    switch nonNotchHeightMode {
                    case .matchMenuBar:
                        nonNotchHeight = 24
                    case .matchRealNotchSize:
                        nonNotchHeight = 32
                    case .custom:
                        nonNotchHeight = 32
                    }
                    NotificationCenter.default.post(
                        name: Notification.Name.notchHeightChanged, object: nil)
                }
                if nonNotchHeightMode == .custom {
                    Slider(value: $nonNotchHeight, in: 0...40, step: 1) {
                        Text("自定义刘海尺寸 - \(nonNotchHeight, specifier: "%.0f")")
                    }
                    .onChange(of: nonNotchHeight) {
                        NotificationCenter.default.post(
                            name: Notification.Name.notchHeightChanged, object: nil)
                    }
                }
            } header: {
                Text("刘海尺寸")
            }

            NotchBehaviour()

            gestureControls()
        }
        .toolbar {
            Button("退出应用") {
                NSApp.terminate(self)
            }
            .controlSize(.extraLarge)
        }
        .accentColor(.effectiveAccent)
        .navigationTitle("通用")
        .onChange(of: openNotchOnHover) {
            if !openNotchOnHover {
                enableGestures = true
            }
        }
    }

    @ViewBuilder
    func gestureControls() -> some View {
        Section {
            Defaults.Toggle(key: .enableGestures) {
                Text("启用手势")
            }
                .disabled(!openNotchOnHover)
            if enableGestures {
                Toggle("横向手势切换媒体", isOn: .constant(false))
                    .disabled(true)
                Defaults.Toggle(key: .closeGestureEnabled) {
                    Text("关闭手势")
                }
                Slider(value: $gestureSensitivity, in: 100...300, step: 100) {
                    HStack {
                        Text("手势灵敏度")
                        Spacer()
                        Text(LocalizedStringKey(gestureSensitivityLabel))
                        .foregroundStyle(.secondary)
                    }
                }
            }
        } header: {
            HStack {
                Text("手势控制")
                customBadge(text: "测试")
            }
        } footer: {
            Text(
                "关闭“悬停时打开刘海”后，可以在刘海区域双指上滑关闭、双指下滑打开。"
            )
            .multilineTextAlignment(.trailing)
            .foregroundStyle(.secondary)
            .font(.caption)
        }
    }

    @ViewBuilder
    func NotchBehaviour() -> some View {
        Section {
            Defaults.Toggle(key: .openNotchOnHover) {
                Text("悬停时打开刘海")
            }
            Defaults.Toggle(key: .enableHaptics) {
                    Text("启用触觉反馈")
            }
            Toggle("记住上次打开的标签页", isOn: $coordinator.openLastTabByDefault)
            if openNotchOnHover {
                Slider(value: $minimumHoverDuration, in: 0...1, step: 0.1) {
                    HStack {
                        Text("悬停延迟")
                        Spacer()
                        Text("\(minimumHoverDuration, specifier: "%.1f")s")
                            .foregroundStyle(.secondary)
                    }
                }
                .onChange(of: minimumHoverDuration) {
                    NotificationCenter.default.post(
                        name: Notification.Name.notchHeightChanged, object: nil)
                }
            }
        } header: {
            Text("刘海行为")
        }
    }

    private var gestureSensitivityLabel: String {
        Defaults[.gestureSensitivity] == 100
            ? "高" : Defaults[.gestureSensitivity] == 200 ? "中" : "低"
    }
}

struct Charge: View {
    var body: some View {
        Form {
            Section {
                Defaults.Toggle(key: .showBatteryIndicator) {
                    Text("显示电池指示器")
                }
                Defaults.Toggle(key: .showPowerStatusNotifications) {
                    Text("显示电源状态通知")
                }
            } header: {
                Text("通用")
            }
            Section {
                Defaults.Toggle(key: .showBatteryPercentage) {
                    Text("显示电池百分比")
                }
                Defaults.Toggle(key: .showPowerStatusIcons) {
                    Text("显示电源状态图标")
                }
            } header: {
                Text("电池信息")
            }
        }
        .onAppear {
            Task { @MainActor in
                await XPCHelperClient.shared.isAccessibilityAuthorized()
            }
        }
        .accentColor(.effectiveAccent)
        .navigationTitle("电池")
    }
}

//struct Downloads: View {
//    @Default(.selectedDownloadIndicatorStyle) var selectedDownloadIndicatorStyle
//    @Default(.selectedDownloadIconStyle) var selectedDownloadIconStyle
//    var body: some View {
//        Form {
//            warningBadge("We don't support downloads yet", "It will be supported later on.")
//            Section {
//                Defaults.Toggle(key: .enableDownloadListener) {
//                    Text("Show download progress")
//                }
//                    .disabled(true)
//                Defaults.Toggle(key: .enableSafariDownloads) {
//                    Text("Enable Safari Downloads")
//                }
//                    .disabled(!Defaults[.enableDownloadListener])
//                Picker("Download indicator style", selection: $selectedDownloadIndicatorStyle) {
//                    Text("Progress bar")
//                        .tag(DownloadIndicatorStyle.progress)
//                    Text("Percentage")
//                        .tag(DownloadIndicatorStyle.percentage)
//                }
//                Picker("Download icon style", selection: $selectedDownloadIconStyle) {
//                    Text("Only app icon")
//                        .tag(DownloadIconStyle.onlyAppIcon)
//                    Text("Only download icon")
//                        .tag(DownloadIconStyle.onlyIcon)
//                    Text("Both")
//                        .tag(DownloadIconStyle.iconAndAppIcon)
//                }
//
//            } header: {
//                HStack {
//                    Text("Download indicators")
//                    comingSoonTag()
//                }
//            }
//            Section {
//                List {
//                    ForEach([].indices, id: \.self) { index in
//                        Text("\(index)")
//                    }
//                }
//                .frame(minHeight: 96)
//                .overlay {
//                    if true {
//                        Text("No excluded apps")
//                            .foregroundStyle(Color(.secondaryLabelColor))
//                    }
//                }
//                .actionBar(padding: 0) {
//                    Group {
//                        Button {
//                        } label: {
//                            Image(systemName: "plus")
//                                .frame(width: 25, height: 16, alignment: .center)
//                                .contentShape(Rectangle())
//                                .foregroundStyle(.secondary)
//                        }
//
//                        Divider()
//                        Button {
//                        } label: {
//                            Image(systemName: "minus")
//                                .frame(width: 20, height: 16, alignment: .center)
//                                .contentShape(Rectangle())
//                                .foregroundStyle(.secondary)
//                        }
//                    }
//                }
//            } header: {
//                HStack(spacing: 4) {
//                    Text("Exclude apps")
//                    comingSoonTag()
//                }
//            }
//        }
//        .navigationTitle("Downloads")
//    }
//}

struct HUD: View {
    @EnvironmentObject var vm: BoringViewModel
    @Default(.inlineHUD) var inlineHUD
    @Default(.enableGradient) var enableGradient
    @Default(.optionKeyAction) var optionKeyAction
    @Default(.hudReplacement) var hudReplacement
    @ObservedObject var coordinator = BoringViewCoordinator.shared
    @State private var accessibilityAuthorized = false
    
    var body: some View {
        Form {
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("替换系统 HUD")
                            .font(.headline)
                        Text("用自定义样式替换 macOS 默认的音量、屏幕亮度和键盘亮度 HUD。")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 40)
                    Defaults.Toggle("", key: .hudReplacement)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.large)
                    .disabled(!accessibilityAuthorized)
                }
                
                if !accessibilityAuthorized {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("替换系统 HUD 需要辅助功能权限。")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 12) {
                            Button("请求辅助功能权限") {
                                XPCHelperClient.shared.requestAccessibilityAuthorization()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .padding(.top, 6)
                }
            }
            
            Section {
                Picker("Option 键行为", selection: $optionKeyAction) {
                    ForEach(OptionKeyAction.allCases) { opt in
                        Text(opt.displayName).tag(opt)
                    }
                }
                
                Picker("进度条样式", selection: $enableGradient) {
                    Text("层级")
                        .tag(false)
                    Text("渐变")
                        .tag(true)
                }
                Defaults.Toggle(key: .systemEventIndicatorShadow) {
                    Text("启用发光效果")
                }
                Defaults.Toggle(key: .systemEventIndicatorUseAccent) {
                    Text("使用强调色渲染进度条")
                }
            } header: {
                Text("通用")
            }
            .disabled(!hudReplacement)
            
            Section {
                Defaults.Toggle(key: .showOpenNotchHUD) {
                    Text("在展开刘海中显示 HUD")
                }
                Defaults.Toggle(key: .showOpenNotchHUDPercentage) {
                    Text("显示百分比")
                }
                .disabled(!Defaults[.showOpenNotchHUD])
            } header: {
                HStack {
                    Text("展开刘海")
                    customBadge(text: "测试")
                }
            }
            .disabled(!hudReplacement)
            
            Section {
                Picker("HUD 样式", selection: $inlineHUD) {
                    Text("默认")
                        .tag(false)
                    Text("内联")
                        .tag(true)
                }
                .onChange(of: Defaults[.inlineHUD]) {
                    if Defaults[.inlineHUD] {
                        withAnimation {
                            Defaults[.systemEventIndicatorShadow] = false
                            Defaults[.enableGradient] = false
                        }
                    }
                }
                
                Defaults.Toggle(key: .showClosedNotchHUDPercentage) {
                    Text("显示百分比")
                }
            } header: {
                Text("收起刘海")
            }
            .disabled(!Defaults[.hudReplacement])
        }
        .accentColor(.effectiveAccent)
        .navigationTitle("HUD")
        .task {
            accessibilityAuthorized = await XPCHelperClient.shared.isAccessibilityAuthorized()
        }
        .onAppear {
            XPCHelperClient.shared.startMonitoringAccessibilityAuthorization()
        }
        .onDisappear {
            XPCHelperClient.shared.stopMonitoringAccessibilityAuthorization()
        }
        .onReceive(NotificationCenter.default.publisher(for: .accessibilityAuthorizationChanged)) { notification in
            if let granted = notification.userInfo?["granted"] as? Bool {
                accessibilityAuthorized = granted
            }
        }
    }
}

struct Media: View {
    @Default(.waitInterval) var waitInterval
    @Default(.mediaController) var mediaController
    @ObservedObject var coordinator = BoringViewCoordinator.shared
    @Default(.hideNotchOption) var hideNotchOption
    @Default(.enableSneakPeek) private var enableSneakPeek
    @Default(.sneakPeekStyles) var sneakPeekStyles

    @Default(.enableLyrics) var enableLyrics

    var body: some View {
        Form {
            Section {
                Picker("音乐来源", selection: $mediaController) {
                    ForEach(availableMediaControllers) { controller in
                        Text(controller.displayName).tag(controller)
                    }
                }
                .onChange(of: mediaController) { _, _ in
                    NotificationCenter.default.post(
                        name: Notification.Name.mediaControllerChanged,
                        object: nil
                    )
                }
            } header: {
                Text("媒体来源")
            } footer: {
                if MusicManager.shared.isNowPlayingDeprecated {
                    HStack {
                        Text("YouTube Music 需要安装这个第三方应用：")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                        Link(
                            "https://github.com/pear-devs/pear-desktop",
                            destination: URL(string: "https://github.com/pear-devs/pear-desktop")!
                        )
                        .font(.caption)
                        .foregroundColor(.blue)  // Ensures it's visibly a link
                    }
                } else {
                    Text(
                        "“正在播放”是旧版本唯一的选项，适用于大多数媒体应用。"
                    )
                    .foregroundStyle(.secondary)
                    .font(.caption)
                }
            }

            MediaDiagnosticsView()
            
            Section {
                Toggle(
                    "显示音乐实时活动",
                    isOn: $coordinator.musicLiveActivityEnabled.animation()
                )
                Toggle("播放变化时显示快速预览", isOn: $enableSneakPeek)
                Picker("快速预览样式", selection: $sneakPeekStyles) {
                    ForEach(SneakPeekStyle.allCases) { style in
                        Text(style.displayName).tag(style)
                    }
                }
                HStack {
                    Stepper(value: $waitInterval, in: 0...10, step: 1) {
                        HStack {
                            Text("媒体无活动超时")
                            Spacer()
                            Text("\(Defaults[.waitInterval], specifier: "%.0f") 秒")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Picker(
                    selection: $hideNotchOption,
                    label:
                        HStack {
                            Text("全屏时行为")
                            customBadge(text: "测试")
                        }
                ) {
                    Text("对所有应用隐藏").tag(HideNotchOption.always)
                    Text("仅对媒体应用隐藏").tag(
                        HideNotchOption.nowPlayingOnly)
                    Text("从不隐藏").tag(HideNotchOption.never)
                }
            } header: {
                Text("媒体播放实时活动")
            }
            
            Section {
                MusicSlotConfigurationView()
                Defaults.Toggle(key: .enableLyrics) {
                    HStack {
                        Text("在歌手名下方显示歌词")
                        customBadge(text: "测试")
                    }
                }
            } header: {
                Text("媒体控制")
            }  footer: {
                Text("自定义音乐播放器中显示的控制项。音量控制会在使用时展开。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accentColor(.effectiveAccent)
        .navigationTitle("媒体")
    }

    // Only show controller options that are available on this macOS version
    private var availableMediaControllers: [MediaControllerType] {
        if MusicManager.shared.isNowPlayingDeprecated {
            return MediaControllerType.allCases.filter { $0 != .nowPlaying }
        } else {
            return MediaControllerType.allCases
        }
    }
}

struct CalendarSettings: View {
    @ObservedObject private var calendarManager = CalendarManager.shared
    @Default(.showCalendar) var showCalendar: Bool
    @Default(.hideCompletedReminders) var hideCompletedReminders
    @Default(.hideAllDayEvents) var hideAllDayEvents
    @Default(.autoScrollToNextEvent) var autoScrollToNextEvent
    @Default(.showChineseCalendarInfo) var showChineseCalendarInfo

    var body: some View {
        Form {
            Defaults.Toggle(key: .showCalendar) {
                Text("显示日历")
            }
            Defaults.Toggle(key: .hideCompletedReminders) {
                Text("隐藏已完成提醒")
            }
            Defaults.Toggle(key: .hideAllDayEvents) {
                Text("隐藏全天日程")
            }
            Defaults.Toggle(key: .autoScrollToNextEvent) {
                Text("自动滚动到下一个日程")
            }
            Defaults.Toggle(key: .showFullEventTitles) {
                Text("始终显示完整日程标题")
            }
            Section {
                Defaults.Toggle(key: .showChineseCalendarInfo) {
                    Text("显示农历和中国节日")
                }
            } header: {
                Text("中国日历")
            } footer: {
                Text("在刘海日历中显示农历日期、常见中国节日，以及 2026 年中国法定休假和补班提示。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section(header: Text("日历")) {
                if calendarManager.calendarAuthorizationStatus != .fullAccess {
                    Text("日历访问权限已被拒绝，请在系统设置中允许访问。")
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                    Button("打开日历设置") {
                        if let settingsURL = URL(
                            string:
                                "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars"
                        ) {
                            NSWorkspace.shared.open(settingsURL)
                        }
                    }
                } else {
                    List {
                        ForEach(calendarManager.eventCalendars, id: \.id) { calendar in
                            Toggle(
                                isOn: Binding(
                                    get: { calendarManager.getCalendarSelected(calendar) },
                                    set: { isSelected in
                                        Task {
                                            await calendarManager.setCalendarSelected(
                                                calendar, isSelected: isSelected)
                                        }
                                    }
                                )
                            ) {
                                Text(calendar.title)
                            }
                            .accentColor(lighterColor(from: calendar.color))
                            .disabled(!showCalendar)
                        }
                    }
                }
            }
            Section(header: Text("提醒事项")) {
                if calendarManager.reminderAuthorizationStatus != .fullAccess {
                    Text("提醒事项访问权限已被拒绝，请在系统设置中允许访问。")
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                    Button("打开提醒事项设置") {
                        if let settingsURL = URL(
                            string:
                                "x-apple.systempreferences:com.apple.preference.security?Privacy_Reminders"
                        ) {
                            NSWorkspace.shared.open(settingsURL)
                        }
                    }
                } else {
                    List {
                        ForEach(calendarManager.reminderLists, id: \.id) { calendar in
                            Toggle(
                                isOn: Binding(
                                    get: { calendarManager.getCalendarSelected(calendar) },
                                    set: { isSelected in
                                        Task {
                                            await calendarManager.setCalendarSelected(
                                                calendar, isSelected: isSelected)
                                        }
                                    }
                                )
                            ) {
                                Text(calendar.title)
                            }
                            .accentColor(lighterColor(from: calendar.color))
                            .disabled(!showCalendar)
                        }
                    }
                }
            }
        }
        .accentColor(.effectiveAccent)
        .navigationTitle("日历")
        .onAppear {
            Task {
                await calendarManager.checkCalendarAuthorization()
                await calendarManager.checkReminderAuthorization()
            }
        }
    }
}

func lighterColor(from nsColor: NSColor, amount: CGFloat = 0.14) -> Color {
    let srgb = nsColor.usingColorSpace(.sRGB) ?? nsColor
    var (r, g, b, a): (CGFloat, CGFloat, CGFloat, CGFloat) = (0,0,0,0)
    srgb.getRed(&r, green: &g, blue: &b, alpha: &a)

    func lighten(_ c: CGFloat) -> CGFloat {
        let increased = c + (1.0 - c) * amount
        return min(max(increased, 0), 1)
    }

    let nr = lighten(r)
    let ng = lighten(g)
    let nb = lighten(b)

    return Color(red: Double(nr), green: Double(ng), blue: Double(nb), opacity: Double(a))
}

struct About: View {
    @State private var showBuildNumber: Bool = false
    let updaterController: SPUStandardUpdaterController?
    @Environment(\.openWindow) var openWindow
    var body: some View {
        VStack {
            Form {
                Section {
                    HStack {
                        Text("版本代号")
                        Spacer()
                        Text(Defaults[.releaseName])
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("版本")
                        Spacer()
                        if showBuildNumber {
                            Text("(\(Bundle.main.buildVersionNumber ?? ""))")
                                .foregroundStyle(.secondary)
                        }
                        Text(Bundle.main.releaseVersionNumber ?? "unkown")
                            .foregroundStyle(.secondary)
                    }
                    .onTapGesture {
                        withAnimation {
                            showBuildNumber.toggle()
                        }
                    }
                } header: {
                    Text("版本信息")
                }

                if let updater = updaterController?.updater {
                    UpdaterSettingsView(updater: updater)
                }

                HStack(spacing: 30) {
                    Spacer(minLength: 0)
                    Button {
                        if let url = URL(string: "https://github.com/Superuser-fank/boring-notch-cn") {
                            NSWorkspace.shared.open(url)
                        }
                    } label: {
                        VStack(spacing: 5) {
                            Image("Github")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 18)
                            Text("GitHub")
                        }
                        .contentShape(Rectangle())
                    }
                    Spacer(minLength: 0)
                }
                .buttonStyle(PlainButtonStyle())
            }
            VStack(spacing: 0) {
                Divider()
                Text("Boring Notch CN 是 Boring Notch 的非官方 fork")
                    .foregroundStyle(.secondary)
                    .padding(.top, 5)
                    .padding(.bottom, 7)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 10)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .toolbar {
            //            Button("Welcome window") {
            //                openWindow(id: "onboarding")
            //            }
            //            .controlSize(.extraLarge)
            if let updater = updaterController?.updater {
                CheckForUpdatesView(updater: updater)
            }
        }
        .navigationTitle("关于")
    }
}

struct Shelf: View {
    
    @Default(.shelfTapToOpen) var shelfTapToOpen: Bool
    @Default(.quickShareProvider) var quickShareProvider
    @Default(.expandedDragDetection) var expandedDragDetection: Bool
    @StateObject private var quickShareService = QuickShareService.shared

    private var selectedProvider: QuickShareProvider? {
        quickShareService.availableProviders.first(where: { $0.id == quickShareProvider })
    }
    
    init() {
        Task { await QuickShareService.shared.discoverAvailableProviders() }
    }
    
    var body: some View {
        Form {
            Section {
                Defaults.Toggle(key: .boringShelf) {
                    Text("启用文件架")
                }
                Defaults.Toggle(key: .openShelfByDefault) {
                    Text("有文件时默认打开文件架")
                }
                Defaults.Toggle(key: .expandedDragDetection) {
                    Text("扩大拖拽检测区域")
                }
                .onChange(of: expandedDragDetection) {
                    NotificationCenter.default.post(
                        name: Notification.Name.expandedDragDetectionChanged,
                        object: nil
                    )
                }
                Defaults.Toggle(key: .copyOnDrag) {
                    Text("拖拽时复制文件")
                }
                Defaults.Toggle(key: .autoRemoveShelfItems) {
                    Text("拖出后从文件架移除")
                }

            } header: {
                HStack {
                    Text("通用")
                }
            }
            
            Section {
                Picker("快速分享服务", selection: $quickShareProvider) {
                    ForEach(quickShareService.availableProviders, id: \.id) { provider in
                        HStack {
                            Group {
                                if let imgData = provider.imageData, let nsImg = NSImage(data: imgData) {
                                    Image(nsImage: nsImg)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                } else {
                                    Image(systemName: "square.and.arrow.up")
                                }
                            }
                            .frame(width: 16, height: 16)
                            .foregroundColor(.accentColor)
                            Text(provider.displayName)
                        }
                        .tag(provider.id)
                    }
                }
                .pickerStyle(.menu)
                
                if let selectedProvider = selectedProvider {
                    HStack {
                        Group {
                            if let imgData = selectedProvider.imageData, let nsImg = NSImage(data: imgData) {
                                Image(nsImage: nsImg)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            } else {
                                Image(systemName: "square.and.arrow.up")
                            }
                        }
                        .frame(width: 16, height: 16)
                        .foregroundColor(.accentColor)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("当前选择：\(selectedProvider.displayName)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(selectedProvider.usesClipboardHandoff ? "会复制到剪贴板并打开应用，需要你手动粘贴发送。" : "拖到文件架的文件会通过此服务分享。")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                // Providers are always enabled; user can pick default service above.
                
            } header: {
                HStack {
                    Text("快速分享")
                }
            } footer: {
                Text("选择从文件架分享文件时使用的服务。微信、QQ、钉钉、飞书会在本机安装后显示；这类投递会复制到剪贴板并打开应用，不会自动选择联系人或自动发送。")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .accentColor(.effectiveAccent)
        .navigationTitle("文件架")
    }
}

//struct Extensions: View {
//    @State private var effectTrigger: Bool = false
//    var body: some View {
//        Form {
//            Section {
//                List {
//                    ForEach(extensionManager.installedExtensions.indices, id: \.self) { index in
//                        let item = extensionManager.installedExtensions[index]
//                        HStack {
//                            AppIcon(for: item.bundleIdentifier)
//                                .resizable()
//                                .frame(width: 24, height: 24)
//                            Text(item.name)
//                            ListItemPopover {
//                                Text("Description")
//                            }
//                            Spacer(minLength: 0)
//                            HStack(spacing: 6) {
//                                Circle()
//                                    .frame(width: 6, height: 6)
//                                    .foregroundColor(
//                                        isExtensionRunning(item.bundleIdentifier)
//                                            ? .green : item.status == .disabled ? .gray : .red
//                                    )
//                                    .conditionalModifier(isExtensionRunning(item.bundleIdentifier))
//                                { view in
//                                    view
//                                        .shadow(color: .green, radius: 3)
//                                }
//                                Text(
//                                    isExtensionRunning(item.bundleIdentifier)
//                                        ? "Running"
//                                        : item.status == .disabled ? "Disabled" : "Stopped"
//                                )
//                                .contentTransition(.numericText())
//                                .foregroundStyle(.secondary)
//                                .font(.footnote)
//                            }
//                            .frame(width: 60, alignment: .leading)
//
//                            Menu(
//                                content: {
//                                    Button("Restart") {
//                                        let ws = NSWorkspace.shared
//
//                                        if let ext = ws.runningApplications.first(where: {
//                                            $0.bundleIdentifier == item.bundleIdentifier
//                                        }) {
//                                            ext.terminate()
//                                        }
//
//                                        if let appURL = ws.urlForApplication(
//                                            withBundleIdentifier: item.bundleIdentifier)
//                                        {
//                                            ws.openApplication(
//                                                at: appURL, configuration: .init(),
//                                                completionHandler: nil)
//                                        }
//                                    }
//                                    .keyboardShortcut("R", modifiers: .command)
//                                    Button("Disable") {
//                                        if let ext = NSWorkspace.shared.runningApplications.first(
//                                            where: { $0.bundleIdentifier == item.bundleIdentifier })
//                                        {
//                                            ext.terminate()
//                                        }
//                                        extensionManager.installedExtensions[index].status =
//                                            .disabled
//                                    }
//                                    .keyboardShortcut("D", modifiers: .command)
//                                    Divider()
//                                    Button("Uninstall", role: .destructive) {
//                                        //
//                                    }
//                                },
//                                label: {
//                                    Image(systemName: "ellipsis.circle")
//                                        .foregroundStyle(.secondary)
//                                }
//                            )
//                            .controlSize(.regular)
//                        }
//                        .buttonStyle(PlainButtonStyle())
//                        .padding(.vertical, 5)
//                    }
//                }
//                .frame(minHeight: 120)
//                .actionBar {
//                    Button {
//                    } label: {
//                        HStack(spacing: 3) {
//                            Image(systemName: "plus")
//                            Text("Add manually")
//                        }
//                        .foregroundStyle(.secondary)
//                    }
//                    .disabled(true)
//                    Spacer()
//                    Button {
//                        withAnimation(.linear(duration: 1)) {
//                            effectTrigger.toggle()
//                        } completion: {
//                            effectTrigger.toggle()
//                        }
//                        extensionManager.checkIfExtensionsAreInstalled()
//                    } label: {
//                        HStack(spacing: 3) {
//                            Image(systemName: "arrow.triangle.2.circlepath")
//                                .rotationEffect(effectTrigger ? .degrees(360) : .zero)
//                        }
//                        .foregroundStyle(.secondary)
//                    }
//                }
//                .controlSize(.small)
//                .buttonStyle(PlainButtonStyle())
//                .overlay {
//                    if extensionManager.installedExtensions.isEmpty {
//                        Text("No extension installed")
//                            .foregroundStyle(Color(.secondaryLabelColor))
//                            .padding(.bottom, 22)
//                    }
//                }
//            } header: {
//                HStack(spacing: 0) {
//                    Text("Installed extensions")
//                    if !extensionManager.installedExtensions.isEmpty {
//                        Text(" – \(extensionManager.installedExtensions.count)")
//                            .foregroundStyle(.secondary)
//                    }
//                }
//            }
//        }
//        .accentColor(.effectiveAccent)
//        .navigationTitle("Extensions")
//        // TipsView()
//        // .padding(.horizontal, 19)
//    }
//}

struct Appearance: View {
    @ObservedObject var coordinator = BoringViewCoordinator.shared
    @Default(.mirrorShape) var mirrorShape
    @Default(.sliderColor) var sliderColor
    @Default(.useMusicVisualizer) var useMusicVisualizer
    @Default(.customVisualizers) var customVisualizers
    @Default(.selectedVisualizer) var selectedVisualizer

    let icons: [String] = ["logo2"]
    @State private var selectedIcon: String = "logo2"
    @State private var selectedListVisualizer: CustomVisualizer? = nil
    @State private var isPresented: Bool = false
    @State private var name: String = ""
    @State private var url: String = ""
    @State private var speed: CGFloat = 1.0
    var body: some View {
        Form {
            Section {
                Toggle("始终显示标签页", isOn: $coordinator.alwaysShowTabs)
                Defaults.Toggle(key: .settingsIconInNotch) {
                    Text("在刘海中显示设置图标")
                }

            } header: {
                Text("通用")
            }

            Section {
                Defaults.Toggle(key: .coloredSpectrogram) {
                    Text("彩色频谱图")
                }
                Defaults.Toggle(key: .playerColorTinting) {
                    Text("播放器着色")
                }
                Defaults.Toggle(key: .lightingEffect) {
                    Text("在专辑封面后启用模糊效果")
                }
                Picker("滑块颜色", selection: $sliderColor) {
                    ForEach(SliderColorEnum.allCases, id: \.self) { option in
                        Text(option.displayName)
                    }
                }
            } header: {
                Text("媒体")
            }

            Section {
                Toggle(
                    "使用音乐可视化频谱图",
                    isOn: $useMusicVisualizer.animation()
                )
                .disabled(true)
                if !useMusicVisualizer {
                    if customVisualizers.count > 0 {
                        Picker(
                            "已选择动画",
                            selection: $selectedVisualizer
                        ) {
                            ForEach(
                                customVisualizers,
                                id: \.self
                            ) { visualizer in
                                Text(visualizer.name)
                                    .tag(visualizer)
                            }
                        }
                    } else {
                        HStack {
                            Text("已选择动画")
                            Spacer()
                            Text("没有自定义动画")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } header: {
                HStack {
                    Text("自定义音乐实时活动动画")
                    customBadge(text: "即将推出")
                }
            }

            Section {
                List {
                    ForEach(customVisualizers, id: \.self) { visualizer in
                        HStack {
                            LottieView(
                                url: visualizer.url, speed: visualizer.speed,
                                loopMode: .loop
                            )
                            .frame(width: 30, height: 30, alignment: .center)
                            Text(visualizer.name)
                            Spacer(minLength: 0)
                            if selectedVisualizer == visualizer {
                                Text("已选择")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.secondary)
                                    .padding(.trailing, 8)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.vertical, 2)
                        .background(
                            selectedListVisualizer != nil
                                ? selectedListVisualizer == visualizer
                                    ? Color.effectiveAccent : Color.clear : Color.clear,
                            in: RoundedRectangle(cornerRadius: 5)
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedListVisualizer == visualizer {
                                selectedListVisualizer = nil
                                return
                            }
                            selectedListVisualizer = visualizer
                        }
                    }
                }
                .safeAreaPadding(
                    EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0)
                )
                .frame(minHeight: 120)
                .actionBar {
                    HStack(spacing: 5) {
                        Button {
                            name = ""
                            url = ""
                            speed = 1.0
                            isPresented.toggle()
                        } label: {
                            Image(systemName: "plus")
                                .foregroundStyle(.secondary)
                                .contentShape(Rectangle())
                        }
                        Divider()
                        Button {
                            if selectedListVisualizer != nil {
                                let visualizer = selectedListVisualizer!
                                selectedListVisualizer = nil
                                customVisualizers.remove(
                                    at: customVisualizers.firstIndex(of: visualizer)!)
                                if visualizer == selectedVisualizer && customVisualizers.count > 0 {
                                    selectedVisualizer = customVisualizers[0]
                                }
                            }
                        } label: {
                            Image(systemName: "minus")
                                .foregroundStyle(.secondary)
                                .contentShape(Rectangle())
                        }
                    }
                }
                .controlSize(.small)
                .buttonStyle(PlainButtonStyle())
                .overlay {
                    if customVisualizers.isEmpty {
                        Text("没有自定义可视化效果")
                            .foregroundStyle(Color(.secondaryLabelColor))
                            .padding(.bottom, 22)
                    }
                }
                .sheet(isPresented: $isPresented) {
                    VStack(alignment: .leading) {
                        Text("添加新的可视化效果")
                            .font(.largeTitle.bold())
                            .padding(.vertical)
                        TextField("名称", text: $name)
                        TextField("Lottie JSON URL", text: $url)
                        HStack {
                            Text("速度")
                            Spacer(minLength: 80)
                            Text("\(speed, specifier: "%.1f")s")
                                .multilineTextAlignment(.trailing)
                                .foregroundStyle(.secondary)
                            Slider(value: $speed, in: 0...2, step: 0.1)
                        }
                        .padding(.vertical)
                        HStack {
                            Button {
                                isPresented.toggle()
                            } label: {
                                Text("取消")
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }

                            Button {
                                let visualizer: CustomVisualizer = .init(
                                    UUID: UUID(),
                                    name: name,
                                    url: URL(string: url)!,
                                    speed: speed
                                )

                                if !customVisualizers.contains(visualizer) {
                                    customVisualizers.append(visualizer)
                                }

                                isPresented.toggle()
                            } label: {
                                Text("添加")
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                            .buttonStyle(BorderedProminentButtonStyle())
                        }
                    }
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .controlSize(.extraLarge)
                    .padding()
                }
            } header: {
                HStack(spacing: 0) {
                    Text("自定义可视化效果 (Lottie)")
                    if !Defaults[.customVisualizers].isEmpty {
                        Text(" – \(Defaults[.customVisualizers].count)")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section {
                Defaults.Toggle(key: .showMirror) {
                    Text("启用刘海镜像")
                }
                    .disabled(!checkVideoInput())
                Picker("镜像形状", selection: $mirrorShape) {
                    Text("圆形")
                        .tag(MirrorShapeEnum.circle)
                    Text("方形")
                        .tag(MirrorShapeEnum.rectangle)
                }
                Defaults.Toggle(key: .showNotHumanFace) {
                    Text("空闲时显示表情动画")
                }
            } header: {
                HStack {
                    Text("附加功能")
                }
            }
        }
        .accentColor(.effectiveAccent)
        .navigationTitle("外观")
    }

    func checkVideoInput() -> Bool {
        if AVCaptureDevice.default(for: .video) != nil {
            return true
        }

        return false
    }
}

struct Advanced: View {
    @Default(.useCustomAccentColor) var useCustomAccentColor
    @Default(.customAccentColorData) var customAccentColorData
    @Default(.extendHoverArea) var extendHoverArea
    @Default(.showOnLockScreen) var showOnLockScreen
    @Default(.hideFromScreenRecording) var hideFromScreenRecording
    
    @State private var customAccentColor: Color = .accentColor
    @State private var selectedPresetColor: PresetAccentColor? = nil
    let icons: [String] = ["logo2"]
    @State private var selectedIcon: String = "logo2"
    
    // macOS accent colors
    enum PresetAccentColor: String, CaseIterable, Identifiable {
        case blue = "Blue"
        case purple = "Purple"
        case pink = "Pink"
        case red = "Red"
        case orange = "Orange"
        case yellow = "Yellow"
        case green = "Green"
        case graphite = "Graphite"
        
        var id: String { self.rawValue }
        
        var color: Color {
            switch self {
            case .blue: return Color(red: 0.0, green: 0.478, blue: 1.0)
            case .purple: return Color(red: 0.686, green: 0.322, blue: 0.871)
            case .pink: return Color(red: 1.0, green: 0.176, blue: 0.333)
            case .red: return Color(red: 1.0, green: 0.271, blue: 0.227)
            case .orange: return Color(red: 1.0, green: 0.584, blue: 0.0)
            case .yellow: return Color(red: 1.0, green: 0.8, blue: 0.0)
            case .green: return Color(red: 0.4, green: 0.824, blue: 0.176)
            case .graphite: return Color(red: 0.557, green: 0.557, blue: 0.576)
            }
        }
    }
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    // Toggle between system and custom
                    Picker("强调色", selection: $useCustomAccentColor) {
                        Text("系统").tag(false)
                        Text("自定义").tag(true)
                    }
                    .pickerStyle(.segmented)
                    
                    if !useCustomAccentColor {
                        // System accent info
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 12) {
                                AccentCircleButton(
                                    isSelected: true,
                                    color: .accentColor,
                                    isSystemDefault: true
                                ) {}
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("正在使用系统强调色")
                                        .font(.body)
                                    Text("使用 macOS 当前系统强调色")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                        }
                    } else {
                        // Custom color options
                        VStack(alignment: .leading, spacing: 12) {
                            Text("颜色预设")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                            
                            HStack(spacing: 12) {
                                ForEach(PresetAccentColor.allCases) { preset in
                                    AccentCircleButton(
                                        isSelected: selectedPresetColor == preset,
                                        color: preset.color,
                                        isMulticolor: false
                                    ) {
                                        selectedPresetColor = preset
                                        customAccentColor = preset.color
                                        saveCustomColor(preset.color)
                                        forceUiUpdate()
                                    }
                                }
                                Spacer()
                            }
                            
                            Divider()
                                .padding(.vertical, 4)
                            
                            // Custom color picker
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("选择颜色")
                                        .font(.body)
                                    Text("选择任意颜色")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                ColorPicker(selection: Binding(
                                    get: { customAccentColor },
                                    set: { newColor in
                                        customAccentColor = newColor
                                        selectedPresetColor = nil
                                        saveCustomColor(newColor)
                                        forceUiUpdate()
                                    }
                                ), supportsOpacity: false) {
                                    ZStack {
                                        Circle()
                                            .fill(customAccentColor)
                                            .frame(width: 32, height: 32)
                                        
                                        if selectedPresetColor == nil {
                                            Circle()
                                                .strokeBorder(.primary.opacity(0.3), lineWidth: 2)
                                                .frame(width: 32, height: 32)
                                        }
                                    }
                                }
                                .labelsHidden()
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Text("强调色")
            } footer: {
                Text("可以使用系统强调色，也可以自定义应用强调色。")
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
            .onAppear {
                initializeAccentColorState()
            }
            
            Section {
                Defaults.Toggle(key: .enableShadow) {
                    Text("启用窗口阴影")
                }
                Defaults.Toggle(key: .cornerRadiusScaling) {
                    Text("圆角缩放")
                }
            } header: {
                Text("窗口外观")
            }
            
            Section {
                HStack {
                    ForEach(icons, id: \.self) { icon in
                        Spacer()
                        VStack {
                            Image(icon)
                                .resizable()
                                .frame(width: 80, height: 80)
                                .background(
                                    RoundedRectangle(cornerRadius: 20, style: .circular)
                                        .strokeBorder(
                                            icon == selectedIcon ? Color.effectiveAccent : .clear,
                                            lineWidth: 2.5
                                        )
                                )

                            Text("默认")
                                .fontWeight(.medium)
                                .font(.caption)
                                .foregroundStyle(icon == selectedIcon ? .white : .secondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(icon == selectedIcon ? Color.effectiveAccent : .clear)
                                )
                        }
                        .onTapGesture {
                            withAnimation {
                                selectedIcon = icon
                            }
                            NSApp.applicationIconImage = NSImage(named: icon)
                        }
                        Spacer()
                    }
                }
                .disabled(true)
            } header: {
                HStack {
                    Text("应用图标")
                    customBadge(text: "即将推出")
                }
            }
            
            Section {
                Defaults.Toggle(key: .extendHoverArea) {
                    Text("扩展悬停区域")
                }
                Defaults.Toggle(key: .hideTitleBar) {
                    Text("隐藏标题栏")
                }
                Defaults.Toggle(key: .showOnLockScreen) {
                    Text("锁屏时显示刘海")
                }
                Defaults.Toggle(key: .hideFromScreenRecording) {
                    Text("屏幕录制时隐藏")
                }
            } header: {
                Text("窗口行为")
            }
        }
        .accentColor(.effectiveAccent)
        .navigationTitle("高级")
        .onAppear {
            loadCustomColor()
        }
    }
    
    private func forceUiUpdate() {
        // Force refresh the UI
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notification.Name("AccentColorChanged"), object: nil)
        }
    }
    
    private func saveCustomColor(_ color: Color) {
        let nsColor = NSColor(color)
        if let colorData = try? NSKeyedArchiver.archivedData(withRootObject: nsColor, requiringSecureCoding: false) {
            Defaults[.customAccentColorData] = colorData
            forceUiUpdate()
        }
    }
    
    private func loadCustomColor() {
        if let colorData = Defaults[.customAccentColorData],
           let nsColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: colorData) {
            customAccentColor = Color(nsColor: nsColor)
            
            // Check if loaded color matches a preset
            selectedPresetColor = nil
            for preset in PresetAccentColor.allCases {
                if colorsAreEqual(Color(nsColor: nsColor), preset.color) {
                    selectedPresetColor = preset
                    break
                }
            }
        }
    }
    
    private func colorsAreEqual(_ color1: Color, _ color2: Color) -> Bool {
        let nsColor1 = NSColor(color1).usingColorSpace(.sRGB) ?? NSColor(color1)
        let nsColor2 = NSColor(color2).usingColorSpace(.sRGB) ?? NSColor(color2)
        
        return abs(nsColor1.redComponent - nsColor2.redComponent) < 0.01 &&
               abs(nsColor1.greenComponent - nsColor2.greenComponent) < 0.01 &&
               abs(nsColor1.blueComponent - nsColor2.blueComponent) < 0.01
    }
    
    private func initializeAccentColorState() {
        if !useCustomAccentColor {
            selectedPresetColor = nil // Multicolor is selected when useCustomAccentColor is false
        } else {
            loadCustomColor()
        }
    }
}

// MARK: - Accent Circle Button Component
struct AccentCircleButton: View {
    let isSelected: Bool
    let color: Color
    var isSystemDefault: Bool = false
    var isMulticolor: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Color circle
                Circle()
                    .fill(color)
                    .frame(width: 32, height: 32)
                
                // Subtle border
                Circle()
                    .strokeBorder(Color.primary.opacity(0.15), lineWidth: 1)
                    .frame(width: 32, height: 32)
                
                // Apple-style highlight ring around the middle when selected
                if isSelected {
                    Circle()
                        .strokeBorder(
                            Color.white.opacity(0.5),
                            lineWidth: 2
                        )
                        .frame(width: 28, height: 28)
                }
            }
        }
        .buttonStyle(.plain)
        .help(isSystemDefault ? NSLocalizedString("使用 macOS 系统强调色", comment: "") : "")
    }
}

struct Shortcuts: View {
    var body: some View {
        Form {
            Section {
                KeyboardShortcuts.Recorder("切换快速预览：", name: .toggleSneakPeek)
            } header: {
                Text("媒体")
            } footer: {
                Text(
                    "快速预览会在刘海下方短暂显示媒体标题和歌手。"
                )
                .multilineTextAlignment(.trailing)
                .foregroundStyle(.secondary)
                .font(.caption)
            }
            Section {
                KeyboardShortcuts.Recorder("切换刘海展开：", name: .toggleNotchOpen)
            }
        }
        .accentColor(.effectiveAccent)
        .navigationTitle("快捷键")
    }
}

private struct ChinaSetupHelpSection: View {
    @State private var copiedQuarantineCommand = false

    private let quarantineCommand = #"xattr -dr com.apple.quarantine "/Applications/Boring Notch CN.app""#

    var body: some View {
        Section {
            HelpActionRow(
                icon: "shield.lefthalf.filled",
                title: "首次打开被 macOS 拦截",
                description: "当前公开构建未 notarize。如果系统提示无法打开，可以复制命令到终端执行。"
            ) {
                Button(copiedQuarantineCommand ? "已复制" : "复制解除隔离命令") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(quarantineCommand, forType: .string)
                    copiedQuarantineCommand = true
                }
            }

            HelpActionRow(
                icon: "figure.wave.circle",
                title: "辅助功能权限",
                description: "媒体键、音量/亮度 HUD 替换和部分交互需要此权限。"
            ) {
                Button("打开辅助功能设置") {
                    openSystemSettings("x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
                }
            }

            HelpActionRow(
                icon: "calendar.badge.clock",
                title: "日历和提醒事项权限",
                description: "如果刘海里没有日程或提醒，请在系统设置里允许访问。"
            ) {
                HStack {
                    Button("日历") {
                        openSystemSettings("x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars")
                    }
                    Button("提醒事项") {
                        openSystemSettings("x-apple.systempreferences:com.apple.preference.security?Privacy_Reminders")
                    }
                }
            }
        } header: {
            Text("中国用户上手")
        } footer: {
            Text("这些入口只打开 macOS 系统设置或复制本地命令，不会上传数据。")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct HelpActionRow<Actions: View>: View {
    let icon: String
    let title: String
    let description: String
    @ViewBuilder let actions: () -> Actions

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 26)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 24)
            actions()
        }
        .padding(.vertical, 2)
    }
}

private struct MediaDiagnosticsView: View {
    @Default(.mediaController) private var mediaController
    @ObservedObject private var musicManager = MusicManager.shared
    @State private var checkedAt = Date()

    private var diagnostic: MediaSourceDiagnostic {
        MediaSourceDiagnostic(controller: mediaController)
    }

    private var selectedAppRunning: Bool {
        guard !diagnostic.bundleIdentifiers.isEmpty else {
            return musicManager.bundleIdentifier != nil
        }

        return NSWorkspace.shared.runningApplications.contains { app in
            guard let bundleIdentifier = app.bundleIdentifier else { return false }
            return diagnostic.matches(bundleIdentifier)
        }
    }

    private var detectedBundleIdentifier: String {
        musicManager.bundleIdentifier ?? "未检测到"
    }

    private var detectedMatchesSelectedSource: Bool {
        guard let bundleIdentifier = musicManager.bundleIdentifier else { return false }
        return diagnostic.matches(bundleIdentifier)
    }

    private var hasPlaybackData: Bool {
        let title = musicManager.songTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let artist = musicManager.artistName.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasRealTitle = !title.isEmpty && title != "I'm Handsome"
        let hasRealArtist = !artist.isEmpty && artist != "Me"
        return hasRealTitle && hasRealArtist && detectedMatchesSelectedSource
    }

    private var playbackDataStatus: DiagnosticStatus {
        if hasPlaybackData {
            return .ok("已检测到歌曲信息")
        }
        if selectedAppRunning {
            return .warning("播放器已打开，等待正在播放数据")
        }
        return .inactive("未检测到播放器")
    }

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                DiagnosticStatusRow(
                    title: "当前媒体来源",
                    value: diagnostic.displayName,
                    status: .ok("已选择")
                )
                DiagnosticStatusRow(
                    title: "播放器状态",
                    value: selectedAppRunning ? "正在运行" : "未运行",
                    status: selectedAppRunning ? .ok("已打开") : .warning("请先打开播放器")
                )
                DiagnosticStatusRow(
                    title: "正在播放数据",
                    value: detectedBundleIdentifier,
                    status: playbackDataStatus
                )
                DiagnosticStatusRow(
                    title: "基础控制",
                    value: diagnostic.controlSummary,
                    status: diagnostic.controlStatus
                )

                if !hasPlaybackData {
                    Text(diagnostic.troubleshootingHint)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 2)
                }

                HStack {
                    Button("刷新媒体状态") {
                        checkedAt = Date()
                        MusicManager.shared.forceUpdate()
                    }
                    Button("打开播放器") {
                        openPreferredApp()
                    }
                    .disabled(diagnostic.bundleIdentifiers.isEmpty)
                    Spacer()
                    Text("上次检查 \(checkedAt.formatted(date: .omitted, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.top, 4)
            }
            .padding(.vertical, 4)
        } header: {
            Text("媒体诊断")
        } footer: {
            Text("网易云音乐等第三方播放器通过 macOS 正在播放数据识别。检测不到时，先播放一首歌，再点刷新。")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func openPreferredApp() {
        guard let bundleIdentifier = diagnostic.bundleIdentifiers.first,
              let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) else {
            return
        }

        let configuration = NSWorkspace.OpenConfiguration()
        NSWorkspace.shared.openApplication(at: appURL, configuration: configuration)
    }
}

private struct DiagnosticStatusRow: View {
    let title: String
    let value: String
    let status: DiagnosticStatus

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: status.symbolName)
                .foregroundStyle(status.color)
                .frame(width: 18)
            Text(title)
                .foregroundStyle(.secondary)
                .frame(width: 100, alignment: .leading)
            Text(value)
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer()
            Text(status.label)
                .font(.caption)
                .foregroundStyle(status.color)
        }
    }
}

private enum DiagnosticStatus {
    case ok(String)
    case warning(String)
    case inactive(String)

    var label: String {
        switch self {
        case .ok(let label), .warning(let label), .inactive(let label):
            return label
        }
    }

    var symbolName: String {
        switch self {
        case .ok:
            return "checkmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .inactive:
            return "minus.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .ok:
            return .green
        case .warning:
            return .orange
        case .inactive:
            return .secondary
        }
    }
}

private struct MediaSourceDiagnostic {
    let controller: MediaControllerType

    var displayName: String {
        controller.displayName
    }

    var bundleIdentifiers: [String] {
        switch controller {
        case .nowPlaying:
            return []
        case .appleMusic:
            return ["com.apple.Music"]
        case .spotify:
            return ["com.spotify.client"]
        case .netEaseMusic:
            return ["com.netease.163music"]
        case .qqMusic:
            return ["com.tencent.QQMusicMac", "com.tencent.QQMusic"]
        case .youtubeMusic:
            return ["com.github.th-ch.youtube-music"]
        }
    }

    var controlSummary: String {
        switch controller {
        case .nowPlaying:
            return "系统基础控制"
        case .appleMusic, .spotify:
            return "播放控制和音量控制"
        case .netEaseMusic, .qqMusic:
            return "播放/暂停/切歌"
        case .youtubeMusic:
            return "依赖第三方客户端插件"
        }
    }

    var controlStatus: DiagnosticStatus {
        switch controller {
        case .youtubeMusic:
            return .warning("需要插件")
        case .netEaseMusic, .qqMusic, .nowPlaying:
            return .warning("依赖系统数据")
        case .appleMusic, .spotify:
            return .ok("直接控制")
        }
    }

    var troubleshootingHint: String {
        switch controller {
        case .nowPlaying:
            return "请先在任意播放器中播放一首歌；如果仍无数据，尝试切换到具体播放器来源。"
        case .appleMusic:
            return "请打开 Apple Music 并播放一首歌；首次控制时 macOS 可能会弹出自动化权限请求。"
        case .spotify:
            return "请打开 Spotify 并播放一首歌；如果控制失败，请确认 Spotify 允许 AppleScript 自动化。"
        case .netEaseMusic:
            return "请打开网易云音乐并先播放一首歌；该来源依赖 macOS 正在播放数据，歌词和收藏不保证可用。"
        case .qqMusic:
            return "请打开 QQ 音乐并先播放一首歌；该来源依赖 macOS 正在播放数据，歌词和收藏不保证可用。"
        case .youtubeMusic:
            return "请确认第三方 YouTube Music 客户端正在运行，并启用了 API 插件。"
        }
    }

    func matches(_ bundleIdentifier: String) -> Bool {
        if controller == .nowPlaying {
            return true
        }
        return bundleIdentifiers.contains {
            bundleIdentifier == $0 || bundleIdentifier.hasSuffix(".\($0)")
        }
    }
}

private func openSystemSettings(_ urlString: String) {
    guard let url = URL(string: urlString) else { return }
    NSWorkspace.shared.open(url)
}

func proFeatureBadge() -> some View {
    Text("升级到 Pro")
        .foregroundStyle(Color(red: 0.545, green: 0.196, blue: 0.98))
        .font(.footnote.bold())
        .padding(.vertical, 3)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 4).stroke(
                Color(red: 0.545, green: 0.196, blue: 0.98), lineWidth: 1))
}

func comingSoonTag() -> some View {
    Text("即将推出")
        .foregroundStyle(.secondary)
        .font(.footnote.bold())
        .padding(.vertical, 3)
        .padding(.horizontal, 6)
        .background(Color(nsColor: .secondarySystemFill))
        .clipShape(.capsule)
}

func customBadge(text: String) -> some View {
    Text(LocalizedStringKey(text))
        .foregroundStyle(.secondary)
        .font(.footnote.bold())
        .padding(.vertical, 3)
        .padding(.horizontal, 6)
        .background(Color(nsColor: .secondarySystemFill))
        .clipShape(.capsule)
}

func warningBadge(_ text: String, _ description: String) -> some View {
    Section {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 22))
                .foregroundStyle(.yellow)
            VStack(alignment: .leading) {
                Text(LocalizedStringKey(text))
                    .font(.headline)
                Text(LocalizedStringKey(description))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}

#Preview {
    HUD()
}
