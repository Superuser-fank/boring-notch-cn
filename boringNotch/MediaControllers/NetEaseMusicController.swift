//
//  NetEaseMusicController.swift
//  boringNotch
//
//  Created by Codex on 2026. 06. 04.
//

import AppKit
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
    var supportsFavorite: Bool { false }

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
    }

    private func isNetEaseBundle(_ bundleIdentifier: String?) -> Bool {
        guard let bundleIdentifier else { return false }
        return bundleIdentifier == Self.netEaseBundleIdentifier
            || bundleIdentifier.hasSuffix(".\(Self.netEaseBundleIdentifier)")
    }
}
