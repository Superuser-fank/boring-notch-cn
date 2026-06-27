//
//  NetEaseMusicController.swift
//  boringNotch
//
//  Created by Codex on 2026. 06. 04.
//

import AppKit
import ApplicationServices
import Combine
import Foundation

final class NetEaseMusicController: ObservableObject, MediaControllerProtocol {
    private static let netEaseBundleIdentifier = "com.netease.163music"

    @Published private var playbackState = PlaybackState(
        bundleIdentifier: netEaseBundleIdentifier
    )

    var playbackStatePublisher: AnyPublisher<PlaybackState, Never> {
        $playbackState.eraseToAnyPublisher()
    }

    var supportsVolumeControl: Bool { false }
    var supportsFavorite: Bool { true }

    private let nowPlayingController: NowPlayingController
    private var cancellables = Set<AnyCancellable>()
    private var hasSeenNetEasePlayback = false

    init?() {
        guard let nowPlayingController = NowPlayingController() else { return nil }
        self.nowPlayingController = nowPlayingController

        nowPlayingController.playbackStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleNowPlayingState(state)
            }
            .store(in: &cancellables)
    }

    func setFavorite(_ favorite: Bool) async {
        guard isActive() else {
            openNetEaseMusic()
            return
        }

        let accessibilityTrusted = isAccessibilityTrusted(promptIfNeeded: true)
        guard accessibilityTrusted else { return }
        guard let currentFavorite = await fetchFavoriteStateFromMenu() else { return }
        guard currentFavorite != favorite else { return }

        let script = favorite ? clickFavoriteScript : clickUnfavoriteScript

        do {
            try await AppleScriptHelper.executeVoid(script)
        } catch {
            return
        }

        try? await Task.sleep(for: .milliseconds(150))
        let confirmedFavorite = await fetchFavoriteStateFromMenu() ?? favorite

        await MainActor.run {
            var updatedState = playbackState
            updatedState.isFavorite = confirmedFavorite
            updatedState.lastUpdated = Date()
            playbackState = updatedState
        }
    }

    func play() async {
        guard canControlCurrentTarget else { return }
        await nowPlayingController.play()
    }

    func pause() async {
        guard canControlCurrentTarget else { return }
        await nowPlayingController.pause()
    }

    func togglePlay() async {
        guard canControlCurrentTarget else {
            openNetEaseMusic()
            return
        }
        await nowPlayingController.togglePlay()
    }

    func nextTrack() async {
        guard canControlCurrentTarget else {
            openNetEaseMusic()
            return
        }
        await nowPlayingController.nextTrack()
    }

    func previousTrack() async {
        guard canControlCurrentTarget else {
            openNetEaseMusic()
            return
        }
        await nowPlayingController.previousTrack()
    }

    func seek(to time: Double) async {
        guard canControlCurrentTarget else { return }
        await nowPlayingController.seek(to: time)
    }

    func toggleShuffle() async {
        guard canControlCurrentTarget else { return }
        await nowPlayingController.toggleShuffle()
    }

    func toggleRepeat() async {
        guard canControlCurrentTarget else { return }
        await nowPlayingController.toggleRepeat()
    }

    func setVolume(_ level: Double) async {}

    func isActive() -> Bool {
        NSWorkspace.shared.runningApplications.contains {
            $0.bundleIdentifier == Self.netEaseBundleIdentifier
        }
    }

    func updatePlaybackInfo() async {
        await nowPlayingController.updatePlaybackInfo()
    }

    private var canControlCurrentTarget: Bool {
        hasSeenNetEasePlayback && isNetEaseBundle(playbackState.bundleIdentifier)
    }

    private func handleNowPlayingState(_ state: PlaybackState) {
        guard isNetEaseBundle(state.bundleIdentifier) else {
            if !isActive() || playbackState.isPlaying || state.isPlaying {
                hasSeenNetEasePlayback = false
                playbackState = PlaybackState(bundleIdentifier: Self.netEaseBundleIdentifier)
            }
            return
        }

        var normalizedState = state
        normalizedState.bundleIdentifier = Self.netEaseBundleIdentifier
        hasSeenNetEasePlayback = true
        playbackState = normalizedState

        Task { [weak self] in
            guard let self,
                  let favoriteState = await self.fetchFavoriteStateFromMenu() else {
                return
            }

            await MainActor.run {
                var updatedState = self.playbackState
                updatedState.isFavorite = favoriteState
                updatedState.lastUpdated = Date()
                self.playbackState = updatedState
            }
        }
    }

    private func fetchFavoriteStateFromMenu() async -> Bool? {
        guard isActive() else { return nil }
        guard isAccessibilityTrusted(promptIfNeeded: false) else { return nil }

        let descriptor: NSAppleEventDescriptor
        do {
            guard let scriptResult = try await AppleScriptHelper.execute(favoriteStateScript) else { return nil }
            descriptor = scriptResult
        } catch {
            return nil
        }

        switch descriptor.stringValue {
        case "favorite":
            return true
        case "notFavorite":
            return false
        default:
            return nil
        }
    }

    private var clickFavoriteScript: String {
        """
        tell application "System Events"
            tell process "NeteaseMusic"
                tell menu bar item "控制" of menu bar 1
                    tell menu 1
                        if exists menu item "喜欢歌曲" then
                            click menu item "喜欢歌曲"
                        else if exists menu item "喜欢" then
                            click menu item "喜欢"
                        end if
                    end tell
                end tell
            end tell
        end tell
        """
    }

    private var clickUnfavoriteScript: String {
        """
        tell application "System Events"
            tell process "NeteaseMusic"
                tell menu bar item "控制" of menu bar 1
                    tell menu 1
                        if exists menu item "取消喜欢" then
                            click menu item "取消喜欢"
                        else if exists menu item "取消喜欢歌曲" then
                            click menu item "取消喜欢歌曲"
                        end if
                    end tell
                end tell
            end tell
        end tell
        """
    }

    private var favoriteStateScript: String {
        """
        tell application "System Events"
            tell process "NeteaseMusic"
                tell menu bar item "控制" of menu bar 1
                    tell menu 1
                        if exists menu item "取消喜欢" then
                            return "favorite"
                        else if exists menu item "取消喜欢歌曲" then
                            return "favorite"
                        else if exists menu item "喜欢歌曲" then
                            return "notFavorite"
                        else if exists menu item "喜欢" then
                            return "notFavorite"
                        else
                            return "unknown"
                        end if
                    end tell
                end tell
            end tell
        end tell
        """
    }

    private func isAccessibilityTrusted(promptIfNeeded: Bool) -> Bool {
        let options = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: promptIfNeeded
        ] as CFDictionary

        return AXIsProcessTrustedWithOptions(options)
    }

    private func isNetEaseBundle(_ bundleIdentifier: String?) -> Bool {
        guard let bundleIdentifier else { return false }
        return bundleIdentifier == Self.netEaseBundleIdentifier
            || bundleIdentifier.hasSuffix(".\(Self.netEaseBundleIdentifier)")
    }

    private func openNetEaseMusic() {
        guard let appURL = NSWorkspace.shared.urlForApplication(
            withBundleIdentifier: Self.netEaseBundleIdentifier
        ) else {
            return
        }

        NSWorkspace.shared.openApplication(at: appURL, configuration: NSWorkspace.OpenConfiguration())
    }
}

final class QQMusicController: ObservableObject, MediaControllerProtocol {
    private static let qqMusicBundleIdentifiers = [
        "com.tencent.QQMusicMac",
        "com.tencent.QQMusic"
    ]
    private static let primaryBundleIdentifier = "com.tencent.QQMusicMac"

    @Published private var playbackState = PlaybackState(
        bundleIdentifier: primaryBundleIdentifier
    )

    var playbackStatePublisher: AnyPublisher<PlaybackState, Never> {
        $playbackState.eraseToAnyPublisher()
    }

    var supportsVolumeControl: Bool { false }
    var supportsFavorite: Bool { false }

    private let nowPlayingController: NowPlayingController
    private var cancellables = Set<AnyCancellable>()
    private var hasSeenQQMusicPlayback = false

    init?() {
        guard let nowPlayingController = NowPlayingController() else { return nil }
        self.nowPlayingController = nowPlayingController

        nowPlayingController.playbackStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleNowPlayingState(state)
            }
            .store(in: &cancellables)
    }

    func setFavorite(_ favorite: Bool) async {}

    func play() async {
        guard canControlCurrentTarget else { return }
        await nowPlayingController.play()
    }

    func pause() async {
        guard canControlCurrentTarget else { return }
        await nowPlayingController.pause()
    }

    func togglePlay() async {
        guard canControlCurrentTarget else { return }
        await nowPlayingController.togglePlay()
    }

    func nextTrack() async {
        guard canControlCurrentTarget else { return }
        await nowPlayingController.nextTrack()
    }

    func previousTrack() async {
        guard canControlCurrentTarget else { return }
        await nowPlayingController.previousTrack()
    }

    func seek(to time: Double) async {
        guard canControlCurrentTarget else { return }
        await nowPlayingController.seek(to: time)
    }

    func toggleShuffle() async {
        guard canControlCurrentTarget else { return }
        await nowPlayingController.toggleShuffle()
    }

    func toggleRepeat() async {
        guard canControlCurrentTarget else { return }
        await nowPlayingController.toggleRepeat()
    }

    func setVolume(_ level: Double) async {}

    func isActive() -> Bool {
        NSWorkspace.shared.runningApplications.contains { app in
            guard let bundleIdentifier = app.bundleIdentifier else { return false }
            return Self.isQQMusicBundle(bundleIdentifier)
        }
    }

    func updatePlaybackInfo() async {
        await nowPlayingController.updatePlaybackInfo()
    }

    private var canControlCurrentTarget: Bool {
        hasSeenQQMusicPlayback && Self.isQQMusicBundle(playbackState.bundleIdentifier)
    }

    private func handleNowPlayingState(_ state: PlaybackState) {
        guard Self.isQQMusicBundle(state.bundleIdentifier) else {
            if !isActive() || playbackState.isPlaying || state.isPlaying {
                hasSeenQQMusicPlayback = false
                playbackState = PlaybackState(bundleIdentifier: Self.primaryBundleIdentifier)
            }
            return
        }

        var normalizedState = state
        normalizedState.bundleIdentifier = Self.primaryBundleIdentifier
        hasSeenQQMusicPlayback = true
        playbackState = normalizedState
    }

    private static func isQQMusicBundle(_ bundleIdentifier: String?) -> Bool {
        guard let bundleIdentifier else { return false }
        return qqMusicBundleIdentifiers.contains { knownBundle in
            bundleIdentifier == knownBundle || bundleIdentifier.hasSuffix(".\(knownBundle)")
        }
    }
}
