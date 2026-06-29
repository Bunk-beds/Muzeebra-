import Foundation
import Observation
import Network
import AppKit
import UniformTypeIdentifiers

@Observable
class SpotifyStore {
    var isLocalMode: Bool = true {
        didSet {
            UserDefaults.standard.set(isLocalMode, forKey: "muzeebra_is_local_mode")
            refreshState()
        }
    }
    
    var isPlaying: Bool = false
    var trackName: String = "No Track Playing"
    var artist: String = ""
    var albumName: String = ""
    var artworkUrl: String = ""
    var durationMs: Int = 0
    var positionMs: Double = 0.0
    var volume: Int = 50
    var isSpotifyRunning: Bool = false
    
    // Web API Data
    var devices: [SpotifyDevice] = []
    var searchResults: [SpotifyTrack] = []
    var playlists: [SpotifyPlaylist] = []
    var queue: [SpotifyTrack] = []
    var activePlaylistDetails: SpotifyPlaylistDetails? = nil
    var loadingPlaylistId: String? = nil
    var userId: String = ""
    var shuffleState: Bool = false
    var recommendedTracks: [SpotifyTrack] = []
    var featuredPlaylists: [SpotifyPlaylist] = []
    var newReleases: [SpotifyAlbum] = []
    var searchQuery: String = "" {
        didSet {
            performSearch()
        }
    }
    
    private var lastRecordedTrackKey: String = ""
    
    var selectedTab: String = "player"
    var activeDeviceId: String = ""
    var localPlayerDeviceId: String = ""
    var showLyrics: Bool = false
    var lowPowerMode: Bool = false {
        didSet {
            UserDefaults.standard.set(lowPowerMode, forKey: "muzeebra_low_power_mode")
            restartTimer()
        }
    }
    
    // Creator profile & Lyrics Properties
    var activeArtistDetails: SpotifyArtistDetails? = nil
    var artistId: String = ""
    var lyricsText: String = ""
    var lyricsSyncedLines: [SyncedLyricLine] = []
    var isLyricsLoading: Bool = false
    var showFullScreenPlayer: Bool = false
    var isDraggingProgress: Bool = false
    private var lastFetchedTrackAndArtist: String = ""
    
    var enableVinylRotation: Bool = true {
        didSet {
            UserDefaults.standard.set(enableVinylRotation, forKey: "muzeebra_enable_vinyl_rotation")
        }
    }
    var enableAmbientGlow: Bool = true {
        didSet {
            UserDefaults.standard.set(enableAmbientGlow, forKey: "muzeebra_enable_ambient_glow")
        }
    }
    var enableLyricsSync: Bool = true {
        didSet {
            UserDefaults.standard.set(enableLyricsSync, forKey: "muzeebra_enable_lyrics_sync")
        }
    }
    
    // Feature & Resource Toggles
    var enableFeatureEqualizer: Bool = false {
        didSet {
            UserDefaults.standard.set(enableFeatureEqualizer, forKey: "muzeebra_enable_feature_equalizer")
            if !enableFeatureEqualizer && selectedTab == "equalizer" {
                selectedTab = "player"
            }
        }
    }
    var enableFeatureVibeInsights: Bool = false {
        didSet {
            UserDefaults.standard.set(enableFeatureVibeInsights, forKey: "muzeebra_enable_feature_vibe_insights")
            if !enableFeatureVibeInsights && selectedTab == "insights" {
                selectedTab = "player"
            }
        }
    }
    var enableFeatureSleepTimer: Bool = false {
        didSet {
            UserDefaults.standard.set(enableFeatureSleepTimer, forKey: "muzeebra_enable_feature_sleep_timer")
            if !enableFeatureSleepTimer {
                stopSleepTimer()
            }
        }
    }
    var enableFeatureMiniPlayer: Bool = false {
        didSet {
            UserDefaults.standard.set(enableFeatureMiniPlayer, forKey: "muzeebra_enable_feature_mini_player")
            if !enableFeatureMiniPlayer && isMiniPlayerMode {
                toggleMiniPlayer()
            }
        }
    }
    
    // Sleep Timer
    var sleepTimerSecondsRemaining: Int = 0
    var isSleepTimerActive: Bool = false
    var sleepTimerSelectedMinutes: Int = 0
    
    // Equalizer
    var eqBands: [Double] = Array(repeating: 0.0, count: 10) {
        didSet {
            pushEqualizerToWebPlayer()
        }
    }
    var eqPreamp: Double = 0.0 {
        didSet {
            pushEqualizerToWebPlayer()
        }
    }
    var eqPresetName: String = "Flat"
    var isEqEnabled: Bool = false {
        didSet {
            pushEqualizerToWebPlayer()
        }
    }
    
    // Audio Insights
    var tempo: Double = 0.0
    var energy: Double = 0.0
    var danceability: Double = 0.0
    var valence: Double = 0.0
    var acousticness: Double = 0.0
    var hasAudioFeatures: Bool = false
    var isAudioFeaturesLoading: Bool = false
    var playlistAccessError: String? = nil
    var exportStatus: String? = nil
    
    // Mini Player Mode
    var isMiniPlayerMode: Bool = false
    

    
    // Performance Statistics
    var memoryUsage: UInt64 = 0
    var cpuUsage: Double = 0.0
    var apiCallCount: Int = 0
    
    // Auth Cache for SwiftUI bindings
    var isLoggedIn: Bool = false
    var accessToken: String? = nil
    
    private var webPollCounter = 0
    private var timer: Timer?
    private var performanceTimer: Timer?
    private let localService = SpotifyLocalService.shared
    private let webService = SpotifyWebService.shared
    
    init() {
        self.isLocalMode = UserDefaults.standard.object(forKey: "muzeebra_is_local_mode") as? Bool ?? true
        self.lowPowerMode = UserDefaults.standard.bool(forKey: "muzeebra_low_power_mode")
        self.enableVinylRotation = UserDefaults.standard.object(forKey: "muzeebra_enable_vinyl_rotation") as? Bool ?? true
        self.enableAmbientGlow = UserDefaults.standard.object(forKey: "muzeebra_enable_ambient_glow") as? Bool ?? true
        self.enableLyricsSync = UserDefaults.standard.object(forKey: "muzeebra_enable_lyrics_sync") as? Bool ?? true
        
        // Resource & Feature Toggles
        self.enableFeatureEqualizer = UserDefaults.standard.bool(forKey: "muzeebra_enable_feature_equalizer")
        self.enableFeatureVibeInsights = UserDefaults.standard.bool(forKey: "muzeebra_enable_feature_vibe_insights")
        self.enableFeatureSleepTimer = UserDefaults.standard.bool(forKey: "muzeebra_enable_feature_sleep_timer")
        self.enableFeatureMiniPlayer = UserDefaults.standard.bool(forKey: "muzeebra_enable_feature_mini_player")
        self.isLoggedIn = webService.isLoggedIn
        self.accessToken = webService.accessToken
        
        setupDistributedNotifications()
        restartTimer()
        setupPerformanceMonitoring()
        refreshState()
    }
    
    func restartTimer() {
        timer?.invalidate()
        let interval = lowPowerMode ? 5.0 : 1.0
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }
    
    func setupPerformanceMonitoring() {
        performanceTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.updatePerformanceStats()
        }
    }
    
    func setupDistributedNotifications() {
        DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.spotify.client.PlaybackStateChanged"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handlePlaybackStateChangedNotification(notification)
        }
    }
    
    private func handlePlaybackStateChangedNotification(_ notification: Notification) {
        guard isLocalMode else { return }
        
        if let userInfo = notification.userInfo {
            let state = userInfo["Player State"] as? String ?? "Paused"
            self.isPlaying = state == "Playing"
            
            let oldTrackName = self.trackName
            let oldArtist = self.artist
            
            self.trackName = userInfo["Name"] as? String ?? "Unknown"
            self.artist = userInfo["Artist"] as? String ?? "Unknown"
            self.albumName = userInfo["Album"] as? String ?? "Unknown"
            self.durationMs = userInfo["Duration"] as? Int ?? 0
            
            if let pos = userInfo["Playback Position"] as? Double {
                self.positionMs = pos * 1000.0
            }
            
            // Note: artwork url is typically read via AppleScript when track changes
            if let art = userInfo["Artwork URL"] as? String {
                self.artworkUrl = art
            } else {
                fetchLocalPlaybackInfo()
            }
            
            if oldTrackName != self.trackName || oldArtist != self.artist {
                fetchLyrics(artistName: self.artist, trackName: self.trackName)
            }
            
            let trackUri = userInfo["Track ID"] as? String ?? ""
            self.recordTrackToHistoryIfNeeded(trackName: self.trackName, artist: self.artist, albumName: self.albumName, uri: trackUri)
        }
    }
    
    func refreshState() {
        self.isLoggedIn = webService.isLoggedIn
        self.accessToken = webService.accessToken
        
        if !isLocalMode && isLoggedIn {
            SpotifyWebPlayerWindowController.shared.setup(with: self)
            if let token = accessToken {
                SpotifyWebPlayerWindowController.shared.updateToken(token)
            }
        } else {
            SpotifyWebPlayerWindowController.shared.closeWindow()
        }
        
        if isLocalMode {
            isSpotifyRunning = localService.isSpotifyRunning
            if isSpotifyRunning {
                fetchLocalPlaybackInfo()
            } else {
                clearPlayerState()
            }
        } else {
            if isLoggedIn {
                fetchWebPlaybackInfo()
                fetchWebDevices()
                fetchWebPlaylists()
                fetchUserId()
                fetchQueue()
                fetchRecommendations()
                fetchDiscoverContent()
            } else {
                clearPlayerState()
            }
        }
    }
    
    private func tick() {
        if enableFeatureSleepTimer && isSleepTimerActive {
            let decrement = lowPowerMode ? 5 : 1
            if sleepTimerSecondsRemaining > decrement {
                sleepTimerSecondsRemaining -= decrement
            } else {
                sleepTimerSecondsRemaining = 0
                isSleepTimerActive = false
                pause()
                MuzeebraLogger.shared.log("Sleep timer expired. Playback paused.")
            }
        }
        
        if isLocalMode {
            isSpotifyRunning = localService.isSpotifyRunning
            if isSpotifyRunning {
                // In local mode, we only poll the position and volume (since these don't trigger notifications)
                if !isDraggingProgress {
                    if let pos = localService.getPlayerPosition() {
                        self.positionMs = pos * 1000.0
                    }
                }
                if let vol = localService.getVolume() {
                    self.volume = vol
                }
            } else {
                clearPlayerState()
            }
        } else {
            let oldToken = self.accessToken
            self.isLoggedIn = webService.isLoggedIn
            self.accessToken = webService.accessToken
            
            if !isLocalMode && isLoggedIn {
                SpotifyWebPlayerWindowController.shared.setup(with: self)
                if oldToken != accessToken, let token = accessToken {
                    SpotifyWebPlayerWindowController.shared.updateToken(token)
                }
            } else {
                SpotifyWebPlayerWindowController.shared.closeWindow()
            }
            
            if isLoggedIn {
                // Smoothly interpolate progress locally if playing
                if !isDraggingProgress && isPlaying && positionMs < Double(durationMs) {
                    self.positionMs += 1000.0
                }
                
                // Slow down polling to avoid 429 rate limit (every 5 seconds when active, 10 when in low power mode)
                let interval = lowPowerMode ? 10 : 5
                webPollCounter += 1
                if webPollCounter >= interval {
                    webPollCounter = 0
                    fetchWebPlaybackInfo()
                    fetchQueue()
                }
            }
        }
    }
    
    func triggerWebStateSync(delay: Double = 0.6) {
        guard !isLocalMode && isLoggedIn else { return }
        
        // Push the counter out to prevent the scheduled tick from immediately fetching again
        self.webPollCounter = -2
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self else { return }
            self.fetchWebPlaybackInfo()
            self.fetchWebDevices()
            self.fetchQueue()
            self.webPollCounter = 0
        }
    }
    
    private func fetchLocalPlaybackInfo() {
        if let state = localService.getPlaybackState() {
            let trackChanged = self.trackName != state.trackName || self.artist != state.artist
            self.isPlaying = state.isPlaying
            self.trackName = state.trackName
            self.artist = state.artist
            self.albumName = state.albumName
            self.durationMs = state.durationMs
            self.positionMs = state.positionSec * 1000.0
            self.artworkUrl = state.artworkUrl
            if let vol = localService.getVolume() {
                self.volume = vol
            }
            if trackChanged {
                self.fetchLyrics(artistName: state.artist, trackName: state.trackName)
            }
            self.recordTrackToHistoryIfNeeded(trackName: self.trackName, artist: self.artist, albumName: self.albumName, uri: state.trackUri)
        }
    }
    
    private func clearPlayerState() {
        isPlaying = false
        trackName = isLocalMode ? "Spotify is Closed" : "Not Logged In"
        artist = isLocalMode ? "Launch Spotify to begin" : "Connect your account in Settings"
        albumName = ""
        artworkUrl = ""
        durationMs = 0
        positionMs = 0.0
        lastFetchedTrackAndArtist = ""
        lyricsText = ""
        lyricsSyncedLines = []
        
        if !isLocalMode {
            SpotifyWebPlayerWindowController.shared.updateMediaSession(
                title: "Muzeebra",
                artist: "Connect your account in Settings",
                album: "",
                artworkUrl: "",
                positionMs: 0.0,
                durationMs: 0,
                isPlaying: false
            )
        }
    }
    
    // MARK: - Sleep Timer Methods
    func startSleepTimer(minutes: Int) {
        guard enableFeatureSleepTimer else { return }
        sleepTimerSelectedMinutes = minutes
        sleepTimerSecondsRemaining = minutes * 60
        isSleepTimerActive = true
        MuzeebraLogger.shared.log("Sleep timer started for \(minutes) minutes.")
    }
    
    func stopSleepTimer() {
        sleepTimerSelectedMinutes = 0
        sleepTimerSecondsRemaining = 0
        isSleepTimerActive = false
        MuzeebraLogger.shared.log("Sleep timer stopped.")
    }
    
    func pause() {
        if isPlaying {
            playPause()
        }
    }
    
    // MARK: - Equalizer Preset Methods
    func applyEqPreset(_ presetName: String) {
        eqPresetName = presetName
        switch presetName {
        case "Flat":
            eqBands = Array(repeating: 0.0, count: 10)
            eqPreamp = 0.0
        case "Classical":
            eqBands = [5.0, 4.0, 3.0, 3.0, -2.0, -2.0, -1.0, 2.0, 4.0, 5.0]
        case "Club":
            eqBands = [0.0, 0.0, 3.0, 5.0, 5.0, 4.0, 2.0, 0.0, 0.0, 0.0]
        case "Dance":
            eqBands = [6.0, 8.0, 6.0, 0.0, 0.0, -2.0, -4.0, -4.0, 0.0, 0.0]
        case "Laptop":
            eqBands = [3.0, 5.0, -1.0, -3.0, -2.0, 1.0, 3.0, 5.0, 7.0, 9.0]
        case "Large Hall":
            eqBands = [6.0, 6.0, 3.0, 3.0, 0.0, -3.0, -3.0, -3.0, 0.0, 0.0]
        case "Party":
            eqBands = [4.0, 4.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 4.0, 4.0]
        case "Pop":
            eqBands = [-2.0, -1.0, 1.0, 3.0, 4.0, 4.0, 2.0, 0.0, -1.0, -2.0]
        case "Reggae":
            eqBands = [0.0, 0.0, -1.0, -3.0, 0.0, 4.0, 4.0, 0.0, 0.0, 0.0]
        case "Rock":
            eqBands = [5.0, 3.0, -3.0, -5.0, -2.0, 2.0, 5.0, 7.0, 7.0, 7.0]
        case "Soft":
            eqBands = [2.0, 1.0, 0.0, -1.0, -1.0, 1.0, 3.0, 4.0, 5.0, 5.0]
        case "Techno":
            eqBands = [5.0, 4.0, 0.0, -3.0, -2.0, 0.0, 5.0, 6.0, 6.0, 5.0]
        case "Vocal":
            eqBands = [-3.0, -5.0, -5.0, 1.0, 5.0, 5.0, 4.0, 2.0, 0.0, -3.0]
        default:
            break
        }
    }
    func pushEqualizerToWebPlayer() {
        guard enableFeatureEqualizer && !isLocalMode else { return }
        SpotifyWebPlayerWindowController.shared.updateEqualizer(
            isEnabled: isEqEnabled,
            bands: eqBands,
            preamp: eqPreamp
        )
    }
    
    // MARK: - Mini Player Mode Methods
    func toggleMiniPlayer() {
        guard enableFeatureMiniPlayer else { return }
        isMiniPlayerMode.toggle()
        
        DispatchQueue.main.async {
            if let window = NSApp.windows.first(where: { $0.isVisible && !$0.title.contains("Engine") }) {
                if self.isMiniPlayerMode {
                    window.level = .floating
                    window.setContentSize(NSSize(width: 320, height: 110))
                    window.styleMask.remove(.resizable)
                } else {
                    window.level = .normal
                    window.setContentSize(NSSize(width: 800, height: 500))
                    window.styleMask.insert(.resizable)
                }
            }
        }
    }
    
    // MARK: - Audio Insights API Methods
    func fetchAudioFeatures(for uri: String) {
        guard enableFeatureVibeInsights, isLoggedIn, uri.contains("spotify:track:") else { 
            self.hasAudioFeatures = false
            return 
        }
        let trackId = uri.replacingOccurrences(of: "spotify:track:", with: "")
        guard !trackId.isEmpty else { return }
        
        self.isAudioFeaturesLoading = true
        webService.performRequest(endpoint: "/v1/audio-features/\(trackId)", method: "GET") { [weak self] result in
            DispatchQueue.main.async {
                self?.isAudioFeaturesLoading = false
                switch result {
                case .success(let data):
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        self?.tempo = json["tempo"] as? Double ?? 0.0
                        self?.energy = json["energy"] as? Double ?? 0.0
                        self?.danceability = json["danceability"] as? Double ?? 0.0
                        self?.valence = json["valence"] as? Double ?? 0.0
                        self?.acousticness = json["acousticness"] as? Double ?? 0.0
                        self?.hasAudioFeatures = true
                    }
                case .failure:
                    self?.hasAudioFeatures = false
                }
            }
        }
    }
    
    // Commands
    func playPause() {
        if isLocalMode {
            localService.playPause()
            isPlaying.toggle()
        } else {
            let isLocalWebPlayer = activeDeviceId == localPlayerDeviceId && !localPlayerDeviceId.isEmpty
            if isLocalWebPlayer {
                isPlaying.toggle()
                SpotifyWebPlayerWindowController.shared.togglePlay()
                self.triggerWebStateSync(delay: 0.6)
            } else {
                let endpoint = isPlaying ? "/v1/me/player/pause" : "/v1/me/player/play"
                webService.performRequest(endpoint: endpoint, method: "PUT") { [weak self] res in
                    if case .success = res {
                        DispatchQueue.main.async {
                            self?.isPlaying.toggle()
                            self?.triggerWebStateSync(delay: 0.5)
                        }
                    }
                }
            }
        }
    }
    
    func nextTrack() {
        if isLocalMode {
            localService.nextTrack()
        } else {
            let isLocalWebPlayer = activeDeviceId == localPlayerDeviceId && !localPlayerDeviceId.isEmpty
            if isLocalWebPlayer {
                SpotifyWebPlayerWindowController.shared.nextTrack()
                self.triggerWebStateSync(delay: 0.8)
            } else {
                webService.performRequest(endpoint: "/v1/me/player/next", method: "POST") { [weak self] res in
                    if case .success = res {
                        DispatchQueue.main.async { self?.triggerWebStateSync(delay: 0.8) }
                    }
                }
            }
        }
    }
    
    func previousTrack() {
        if isLocalMode {
            localService.previousTrack()
        } else {
            let isLocalWebPlayer = activeDeviceId == localPlayerDeviceId && !localPlayerDeviceId.isEmpty
            if isLocalWebPlayer {
                SpotifyWebPlayerWindowController.shared.previousTrack()
                self.triggerWebStateSync(delay: 0.8)
            } else {
                webService.performRequest(endpoint: "/v1/me/player/previous", method: "POST") { [weak self] res in
                    if case .success = res {
                        DispatchQueue.main.async { self?.triggerWebStateSync(delay: 0.8) }
                    }
                }
            }
        }
    }
    
    func seek(to progressPercent: Double) {
        let targetMs = Double(durationMs) * progressPercent
        if isLocalMode {
            localService.seek(to: targetMs / 1000.0)
            self.positionMs = targetMs
        } else {
            let isLocalWebPlayer = activeDeviceId == localPlayerDeviceId && !localPlayerDeviceId.isEmpty
            if isLocalWebPlayer {
                self.positionMs = targetMs
                SpotifyWebPlayerWindowController.shared.seek(to: Int(targetMs))
                self.triggerWebStateSync(delay: 0.6)
            } else {
                let endpoint = "/v1/me/player/seek?position_ms=\(Int(targetMs))"
                webService.performRequest(endpoint: endpoint, method: "PUT") { [weak self] res in
                    if case .success = res {
                        DispatchQueue.main.async {
                            self?.positionMs = targetMs
                            self?.triggerWebStateSync(delay: 0.6)
                        }
                    }
                }
            }
        }
    }
    
    func setVolume(to vol: Int) {
        self.volume = vol
        if isLocalMode {
            localService.setVolume(vol)
        } else {
            let isLocalWebPlayer = activeDeviceId == localPlayerDeviceId && !localPlayerDeviceId.isEmpty
            if isLocalWebPlayer {
                SpotifyWebPlayerWindowController.shared.setVolume(Double(vol) / 100.0)
                let endpoint = "/v1/me/player/volume?volume_percent=\(vol)"
                webService.performRequest(endpoint: endpoint, method: "PUT") { _ in }
            } else {
                let endpoint = "/v1/me/player/volume?volume_percent=\(vol)"
                webService.performRequest(endpoint: endpoint, method: "PUT") { [weak self] res in
                    if case .success = res {
                        DispatchQueue.main.async { self?.triggerWebStateSync(delay: 0.6) }
                    }
                }
            }
        }
    }
    
    // Web API Integrations
    func fetchWebPlaybackInfo() {
        webService.performRequest(endpoint: "/v1/me/player") { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure:
                break
            case .success(let data):
                guard !data.isEmpty else { return }
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        DispatchQueue.main.async {
                            self.isPlaying = json["is_playing"] as? Bool ?? false
                            if !self.isDraggingProgress {
                                self.positionMs = json["progress_ms"] as? Double ?? 0.0
                            }
                            self.shuffleState = json["shuffle_state"] as? Bool ?? false
                            
                            if let item = json["item"] as? [String: Any] {
                                let newTrackName = item["name"] as? String ?? ""
                                self.durationMs = item["duration_ms"] as? Int ?? 0
                                
                                var newArtist = ""
                                var newArtistId = ""
                                if let artists = item["artists"] as? [[String: Any]], let firstArtist = artists.first {
                                    newArtist = firstArtist["name"] as? String ?? ""
                                    newArtistId = firstArtist["id"] as? String ?? ""
                                }
                                
                                let trackChanged = self.trackName != newTrackName || self.artist != newArtist
                                if trackChanged || (self.lyricsSyncedLines.isEmpty && self.lyricsText.isEmpty) {
                                    self.trackName = newTrackName
                                    self.artist = newArtist
                                    self.artistId = newArtistId
                                    self.fetchLyrics(artistName: newArtist, trackName: newTrackName)
                                }
                                if let album = item["album"] as? [String: Any] {
                                    self.albumName = album["name"] as? String ?? ""
                                    if let images = album["images"] as? [[String: Any]], let firstImage = images.first {
                                        self.artworkUrl = firstImage["url"] as? String ?? ""
                                    }
                                }
                                
                                let trackUri = item["uri"] as? String ?? ""
                                self.recordTrackToHistoryIfNeeded(trackName: newTrackName, artist: newArtist, albumName: self.albumName, uri: trackUri)
                                
                                SpotifyWebPlayerWindowController.shared.updateMediaSession(
                                    title: self.trackName,
                                    artist: self.artist,
                                    album: self.albumName,
                                    artworkUrl: self.artworkUrl,
                                    positionMs: self.positionMs,
                                    durationMs: self.durationMs,
                                    isPlaying: self.isPlaying
                                )
                            }
                            if let device = json["device"] as? [String: Any] {
                                self.volume = device["volume_percent"] as? Int ?? 50
                                self.activeDeviceId = device["id"] as? String ?? ""
                            }
                        }
                    }
                } catch {}
            }
        }
    }
    
    func updateFromWebPlayerState(_ state: [String: Any]) {
        guard !isLocalMode else { return }
        
        let newTrackName = state["trackName"] as? String ?? ""
        let newArtist = state["artist"] as? String ?? ""
        let newAlbumName = state["albumName"] as? String ?? ""
        let newArtworkUrl = state["artworkUrl"] as? String ?? ""
        let newIsPlaying = state["isPlaying"] as? Bool ?? false
        let newPositionMs = state["positionMs"] as? Double ?? 0.0
        let newDurationMs = state["durationMs"] as? Int ?? 0
        
        let trackChanged = self.trackName != newTrackName || self.artist != newArtist
        
        self.isPlaying = newIsPlaying
        if !self.isDraggingProgress {
            self.positionMs = newPositionMs
        }
        self.durationMs = newDurationMs
        
        if trackChanged || (self.lyricsSyncedLines.isEmpty && self.lyricsText.isEmpty) {
            self.trackName = newTrackName
            self.artist = newArtist
            self.albumName = newAlbumName
            self.artworkUrl = newArtworkUrl
            self.fetchLyrics(artistName: newArtist, trackName: newTrackName)
        }
    }
    
    func fetchWebDevices() {
        webService.performRequest(endpoint: "/v1/me/player/devices") { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure:
                break
            case .success(let data):
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let devicesJson = json["devices"] as? [[String: Any]] {
                        let parsedDevices = devicesJson.map { d -> SpotifyDevice in
                            SpotifyDevice(
                                id: d["id"] as? String ?? "",
                                name: d["name"] as? String ?? "Unknown Device",
                                type: d["type"] as? String ?? "Computer",
                                isActive: d["is_active"] as? Bool ?? false
                            )
                        }
                        DispatchQueue.main.async {
                            self.devices = parsedDevices
                        }
                    }
                } catch {}
            }
        }
    }
    
    func transferPlayback(to deviceId: String) {
        let body: [String: Any] = ["device_ids": [deviceId], "play": true]
        webService.performRequest(endpoint: "/v1/me/player", method: "PUT", jsonBody: body) { [weak self] result in
            if case .success = result {
                DispatchQueue.main.async {
                    self?.activeDeviceId = deviceId
                    self?.fetchWebDevices()
                }
            }
        }
    }
    
    func fetchWebPlaylists() {
        webService.performRequest(endpoint: "/v1/me/playlists?limit=20") { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure:
                break
            case .success(let data):
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let items = json["items"] as? [[String: Any]] {
                        let parsedPlaylists = items.map { p -> SpotifyPlaylist in
                            var imgUrl = ""
                            if let images = p["images"] as? [[String: Any]], let firstImg = images.first {
                                imgUrl = firstImg["url"] as? String ?? ""
                            }
                            let trackObj = p["items"] as? [String: Any] ?? p["tracks"] as? [String: Any]
                            let trackCount = trackObj?["total"] as? Int ?? 0
                            return SpotifyPlaylist(
                                id: p["id"] as? String ?? "",
                                name: p["name"] as? String ?? "Untitled",
                                artworkUrl: imgUrl,
                                trackCount: trackCount
                            )
                        }
                        DispatchQueue.main.async {
                            self.playlists = parsedPlaylists
                        }
                    }
                } catch {}
            }
        }
    }
    
    func fetchUserId() {
        guard !isLocalMode && isLoggedIn else { return }
        guard userId.isEmpty else { return }
        webService.performRequest(endpoint: "/v1/me") { [weak self] result in
            if case .success(let data) = result {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let id = json["id"] as? String {
                    DispatchQueue.main.async {
                        self?.userId = id
                    }
                }
            }
        }
    }
    
    func fetchQueue() {
        guard !isLocalMode && isLoggedIn else { return }
        webService.performRequest(endpoint: "/v1/me/player/queue") { [weak self] result in
            if case .success(let data) = result {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let queueJson = json["queue"] as? [[String: Any]] {
                        let parsedQueue = queueJson.prefix(15).map { t -> SpotifyTrack in
                            var albumArt = ""
                            if let album = t["album"] as? [String: Any],
                               let images = album["images"] as? [[String: Any]],
                               let firstImg = images.first {
                                albumArt = firstImg["url"] as? String ?? ""
                            }
                            let artistName = ((t["artists"] as? [[String: Any]])?.first?["name"] as? String) ?? "Unknown Artist"
                            let artId = ((t["artists"] as? [[String: Any]])?.first?["id"] as? String)
                            return SpotifyTrack(
                                id: t["id"] as? String ?? "",
                                uri: t["uri"] as? String ?? "",
                                name: t["name"] as? String ?? "Unknown",
                                artist: artistName,
                                albumName: (t["album"] as? [String: Any])?["name"] as? String ?? "",
                                artworkUrl: albumArt,
                                durationMs: t["duration_ms"] as? Int ?? 0,
                                artistId: artId
                            )
                        }
                        DispatchQueue.main.async {
                            self?.queue = Array(parsedQueue)
                        }
                    }
                } catch {}
            }
        }
    }
    
    func addToQueue(uri: String) {
        guard !isLocalMode && isLoggedIn else { return }
        let encodedUri = uri.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        webService.performRequest(endpoint: "/v1/me/player/queue?uri=\(encodedUri)", method: "POST") { [weak self] result in
            if case .success = result {
                DispatchQueue.main.async {
                    self?.fetchQueue()
                }
            }
        }
    }
    
    func createPlaylist(name: String) {
        guard !isLocalMode && isLoggedIn && !userId.isEmpty else { return }
        let body: [String: Any] = [
            "name": name,
            "description": "Created with Muzeebra",
            "public": false
        ]
        webService.performRequest(endpoint: "/v1/users/\(userId)/playlists", method: "POST", jsonBody: body) { [weak self] result in
            if case .success = result {
                DispatchQueue.main.async {
                    self?.fetchWebPlaylists()
                }
            }
        }
    }
    
    func deletePlaylist(id: String) {
        guard !isLocalMode && isLoggedIn else { return }
        webService.performRequest(endpoint: "/v1/playlists/\(id)/followers", method: "DELETE") { [weak self] result in
            if case .success = result {
                DispatchQueue.main.async {
                    self?.activePlaylistDetails = nil
                    self?.fetchWebPlaylists()
                }
            }
        }
    }
    
    func fetchPlaylistTracks(id: String, name: String, artworkUrl: String) {
        guard !isLocalMode && isLoggedIn else { return }
        
        self.loadingPlaylistId = id
        
        DispatchQueue.main.async {
            self.playlistAccessError = nil
            if self.activePlaylistDetails?.id != id {
                self.activePlaylistDetails = SpotifyPlaylistDetails(
                    id: id,
                    name: name,
                    artworkUrl: artworkUrl,
                    tracks: []
                )
            }
        }
        
        self.fetchAllPlaylistItems(playlistId: id) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                MuzeebraLogger.shared.log("Playlist tracks API request failed: \(error.localizedDescription)")
                if let nsError = error as NSError?, nsError.code == 403 {
                    MuzeebraLogger.shared.log("Attempting public embed scraping fallback for playlist \(id)")
                    self.scrapePublicPlaylist(id: id, name: name, artworkUrl: artworkUrl, updateActiveDetails: true)
                } else {
                    DispatchQueue.main.async {
                        if self.loadingPlaylistId == id {
                            self.playlistAccessError = error.localizedDescription
                            self.activePlaylistDetails = SpotifyPlaylistDetails(
                                id: id,
                                name: name,
                                artworkUrl: artworkUrl,
                                tracks: []
                            )
                        }
                    }
                }
            case .success(let tracks):
                let details = SpotifyPlaylistDetails(
                    id: id,
                    name: name,
                    artworkUrl: artworkUrl,
                    tracks: tracks
                )
                DispatchQueue.main.async {
                    if self.loadingPlaylistId == id {
                        self.playlistAccessError = nil
                        self.activePlaylistDetails = details
                    }
                }
            }
        }
    }
    
    private func scrapePublicPlaylist(id: String, name: String, artworkUrl: String, updateActiveDetails: Bool) {
        MuzeebraLogger.shared.log("[Scraper] scrapePublicPlaylist started for id: \(id), name: \(name)")
        webService.fetchPublicPlaylistEmbed(id: id) { [weak self] result in
            guard let self = self else { 
                MuzeebraLogger.shared.log("[Scraper] scrapePublicPlaylist aborted: SpotifyStore is nil")
                return 
            }
            switch result {
            case .failure(let error):
                MuzeebraLogger.shared.log("[Scraper] Failed to scrape public playlist \(id): \(error.localizedDescription)")
                if updateActiveDetails {
                    DispatchQueue.main.async {
                        if self.loadingPlaylistId == id {
                            self.playlistAccessError = "Public scraping failed: \(error.localizedDescription)"
                            self.activePlaylistDetails = SpotifyPlaylistDetails(
                                id: id,
                                name: name,
                                artworkUrl: artworkUrl,
                                tracks: []
                            )
                        }
                    }
                }
            case .success(let html):
                MuzeebraLogger.shared.log("[Scraper] Successfully fetched embed HTML for \(id). Length: \(html.count)")
                // Parse the __NEXT_DATA__ script content
                if let startRange = html.range(of: "<script id=\"__NEXT_DATA__\" type=\"application/json\">") {
                    let sub = html[startRange.upperBound...]
                    if let endRange = sub.range(of: "</script>") {
                        let jsonString = String(sub[..<endRange.lowerBound])
                        MuzeebraLogger.shared.log("[Scraper] Found __NEXT_DATA__ block (length: \(jsonString.count)). Parsing JSON...")
                        self.parseScrapedPlaylistJSON(jsonString, id: id, name: name, artworkUrl: artworkUrl, updateActiveDetails: updateActiveDetails)
                        return
                    }
                }
                
                MuzeebraLogger.shared.log("[Scraper] Could not find __NEXT_DATA__ script in scraped HTML for playlist \(id)")
                if updateActiveDetails {
                    DispatchQueue.main.async {
                        if self.loadingPlaylistId == id {
                            self.playlistAccessError = "Could not parse public playlist webpage structure"
                            self.activePlaylistDetails = SpotifyPlaylistDetails(
                                id: id,
                                name: name,
                                artworkUrl: artworkUrl,
                                tracks: []
                            )
                        }
                    }
                }
            }
        }
    }
    
    private func parseScrapedPlaylistJSON(_ jsonStr: String, id: String, name: String, artworkUrl: String, updateActiveDetails: Bool) {
        guard let data = jsonStr.data(using: .utf8) else {
            MuzeebraLogger.shared.log("[Scraper] parseScrapedPlaylistJSON: failed to convert jsonStr to UTF8 data")
            if updateActiveDetails {
                DispatchQueue.main.async {
                    if self.loadingPlaylistId == id {
                        self.playlistAccessError = "Data conversion failed"
                    }
                }
            }
            return
        }
        
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let props = json["props"] as? [String: Any],
               let pageProps = props["pageProps"] as? [String: Any],
               let state = pageProps["state"] as? [String: Any],
               let stateData = state["data"] as? [String: Any],
               let entity = stateData["entity"] as? [String: Any] {
                
                let playlistName = entity["name"] as? String ?? name
                var playlistCoverArt = artworkUrl
                if let coverArt = entity["coverArt"] as? [String: Any],
                   let sources = coverArt["sources"] as? [[String: Any]],
                   let firstSource = sources.first {
                    playlistCoverArt = firstSource["url"] as? String ?? artworkUrl
                }
                
                let trackList = entity["trackList"] as? [[String: Any]] ?? []
                MuzeebraLogger.shared.log("[Scraper] parseScrapedPlaylistJSON: successfully parsed JSON structure. Track list size: \(trackList.count)")
                
                let parsedTracks = trackList.compactMap { item -> SpotifyTrack? in
                    guard let uri = item["uri"] as? String, !uri.isEmpty else { return nil }
                    let parts = uri.components(separatedBy: ":")
                    let trackId = parts.last ?? ""
                    
                    let title = item["title"] as? String ?? "Unknown Track"
                    let artistName = item["subtitle"] as? String ?? "Unknown Artist"
                    let duration = item["duration"] as? Int ?? 0
                    
                    return SpotifyTrack(
                        id: trackId,
                        uri: uri,
                        name: title,
                        artist: artistName,
                        albumName: "",
                        artworkUrl: playlistCoverArt,
                        durationMs: duration,
                        artistId: nil
                    )
                }
                
                let details = SpotifyPlaylistDetails(
                    id: id,
                    name: playlistName,
                    artworkUrl: playlistCoverArt,
                    tracks: parsedTracks
                )
                
                let shouldUpdateUI = (updateActiveDetails && self.loadingPlaylistId == id) ||
                                     (!updateActiveDetails && self.activePlaylistDetails?.id == id)
                
                MuzeebraLogger.shared.log("[Scraper] shouldUpdateUI: \(shouldUpdateUI) (updateActiveDetails: \(updateActiveDetails), loadingPlaylistId: \(self.loadingPlaylistId ?? "nil"), activeDetailsId: \(self.activePlaylistDetails?.id ?? "nil"))")
                
                if shouldUpdateUI {
                    DispatchQueue.main.async {
                        self.playlistAccessError = nil
                        self.activePlaylistDetails = details
                    }
                }
            } else {
                MuzeebraLogger.shared.log("[Scraper] Invalid scraped JSON structure for playlist \(id)")
                if updateActiveDetails {
                    DispatchQueue.main.async {
                        if self.loadingPlaylistId == id {
                            self.playlistAccessError = "Invalid public webpage data structure"
                        }
                    }
                }
            }
        } catch {
            MuzeebraLogger.shared.log("[Scraper] Failed to parse scraped JSON for playlist \(id): \(error.localizedDescription)")
            if updateActiveDetails {
                DispatchQueue.main.async {
                    if self.loadingPlaylistId == id {
                        self.playlistAccessError = "JSON parsing error: \(error.localizedDescription)"
                    }
                }
            }
        }
    }
    
    func playPlaylist(id: String, name: String, artworkUrl: String) {
        playContext(uri: "spotify:playlist:\(id)")
        fetchPlaylistTracks(id: id, name: name, artworkUrl: artworkUrl)
    }
    
    private func parseTrackItems(_ items: [[String: Any]]) -> [SpotifyTrack] {
        return items.compactMap { item -> SpotifyTrack? in
            guard let t = item["track"] as? [String: Any] else { return nil }
            var albumArt = ""
            if let album = t["album"] as? [String: Any],
               let images = album["images"] as? [[String: Any]],
               let firstImg = images.first {
                albumArt = firstImg["url"] as? String ?? ""
            }
            let artistName = ((t["artists"] as? [[String: Any]])?.first?["name"] as? String) ?? "Unknown Artist"
            let artId = ((t["artists"] as? [[String: Any]])?.first?["id"] as? String)
            return SpotifyTrack(
                id: t["id"] as? String ?? "",
                uri: t["uri"] as? String ?? "",
                name: t["name"] as? String ?? "Unknown",
                artist: artistName,
                albumName: (t["album"] as? [String: Any])?["name"] as? String ?? "",
                artworkUrl: albumArt,
                durationMs: t["duration_ms"] as? Int ?? 0,
                artistId: artId
            )
        }
    }
    
    private func fetchRemainingPlaylistItemsInParallel(playlistId: String, total: Int, firstPageTracks: [SpotifyTrack], completion: @escaping (Result<[SpotifyTrack], Error>) -> Void) {
        let maxTracks = min(total, 1000) // Safe cap at 1000 tracks
        let limit = 100
        
        var offsets: [Int] = []
        var currentOffset = 100
        while currentOffset < maxTracks {
            offsets.append(currentOffset)
            currentOffset += limit
        }
        
        guard !offsets.isEmpty else {
            completion(.success(firstPageTracks))
            return
        }
        
        let group = DispatchGroup()
        var pages: [Int: [SpotifyTrack]] = [:]
        let queue = DispatchQueue(label: "com.muzeebra.parallelFetchQueue")
        
        for offset in offsets {
            group.enter()
            let endpoint = "/v1/playlists/\(playlistId)/items?limit=\(limit)&offset=\(offset)"
            
            webService.performRequest(endpoint: endpoint) { [weak self] result in
                guard let self = self else {
                    group.leave()
                    return
                }
                
                guard playlistId == self.loadingPlaylistId else {
                    group.leave()
                    return
                }
                
                switch result {
                case .failure(let error):
                    MuzeebraLogger.shared.log("Parallel fetch failed for offset \(offset): \(error.localizedDescription)")
                    group.leave()
                case .success(let data):
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let items = json["items"] as? [[String: Any]] {
                            let parsed = self.parseTrackItems(items)
                            queue.sync {
                                pages[offset] = parsed
                            }
                        }
                    } catch {
                        MuzeebraLogger.shared.log("Failed to parse JSON for parallel offset \(offset): \(error.localizedDescription)")
                    }
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            guard playlistId == self.loadingPlaylistId else {
                completion(.failure(NSError(domain: "Muzeebra", code: -999, userInfo: [NSLocalizedDescriptionKey: "Fetch cancelled"])))
                return
            }
            
            var allTracks = firstPageTracks
            for offset in offsets.sorted() {
                if let pageTracks = pages[offset] {
                    allTracks.append(contentsOf: pageTracks)
                }
            }
            
            completion(.success(allTracks))
        }
    }
    
    func fetchAllPlaylistItems(playlistId: String, offset: Int = 0, accumulated: [SpotifyTrack] = [], completion: @escaping (Result<[SpotifyTrack], Error>) -> Void) {
        guard playlistId == self.loadingPlaylistId else {
            MuzeebraLogger.shared.log("Aborted paginated fetch for playlist \(playlistId) because loadingPlaylistId changed to \(self.loadingPlaylistId ?? "nil")")
            completion(.failure(NSError(domain: "Muzeebra", code: -999, userInfo: [NSLocalizedDescriptionKey: "Fetch cancelled"])))
            return
        }
        
        let endpoint = "/v1/playlists/\(playlistId)/items?limit=100&offset=0"
        webService.performRequest(endpoint: endpoint) { [weak self] result in
            guard let self = self else { return }
            
            guard playlistId == self.loadingPlaylistId else {
                MuzeebraLogger.shared.log("Aborted paginated fetch callback for playlist \(playlistId) because loadingPlaylistId changed")
                completion(.failure(NSError(domain: "Muzeebra", code: -999, userInfo: [NSLocalizedDescriptionKey: "Fetch cancelled"])))
                return
            }
            
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let data):
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let items = json["items"] as? [[String: Any]],
                       let total = json["total"] as? Int {
                        let parsed = self.parseTrackItems(items)
                        
                        if total <= 100 || parsed.isEmpty {
                            completion(.success(parsed))
                        } else {
                            self.fetchRemainingPlaylistItemsInParallel(playlistId: playlistId, total: total, firstPageTracks: parsed, completion: completion)
                        }
                    } else {
                        completion(.failure(NSError(domain: "Muzeebra", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON Structure"])))
                    }
                } catch {
                    completion(.failure(error))
                }
            }
        }
    }
    
    func exportPlaylistsToCSV() {
        guard !isLocalMode && isLoggedIn else { return }
        
        DispatchQueue.main.async {
            let panel = NSOpenPanel()
            panel.canChooseFiles = false
            panel.canChooseDirectories = true
            panel.allowsMultipleSelection = false
            panel.title = "Choose Export Destination Folder"
            panel.prompt = "Export Here"
            
            if panel.runModal() == .OK, let folderURL = panel.url {
                self.exportStatus = "Exporting..."
                
                let playlistsToExport = self.playlists
                if playlistsToExport.isEmpty {
                    self.exportStatus = "No playlists found to export"
                    return
                }
                
                let group = DispatchGroup()
                var successCount = 0
                var failCount = 0
                
                for playlist in playlistsToExport {
                    group.enter()
                    self.fetchAllPlaylistItems(playlistId: playlist.id) { result in
                        switch result {
                        case .failure(let error):
                            MuzeebraLogger.shared.log("Failed to fetch tracks for export of playlist \(playlist.name): \(error.localizedDescription)")
                            failCount += 1
                            group.leave()
                        case .success(let tracks):
                            var csvContent = "Track Name,Artist,Album,URI\n"
                            
                            let escapeCSVField: (String) -> String = { field in
                                let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
                                return "\"\(escaped)\""
                            }
                            
                            for track in tracks {
                                let name = escapeCSVField(track.name)
                                let artist = escapeCSVField(track.artist)
                                let album = escapeCSVField(track.albumName)
                                let uri = escapeCSVField(track.uri)
                                csvContent += "\(name),\(artist),\(album),\(uri)\n"
                            }
                            
                            let safeName = playlist.name
                                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                                .joined(separator: "_")
                            let fileURL = folderURL.appendingPathComponent("\(safeName).csv")
                            
                            do {
                                try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)
                                successCount += 1
                            } catch {
                                MuzeebraLogger.shared.log("Failed to write CSV file for playlist \(playlist.name): \(error.localizedDescription)")
                                failCount += 1
                            }
                            group.leave()
                        }
                    }
                }
                
                group.notify(queue: .main) {
                    if failCount > 0 {
                        self.exportStatus = "Export completed: \(successCount) succeeded, \(failCount) failed"
                    } else {
                        self.exportStatus = "Successfully exported \(successCount) playlists!"
                    }
                }
            }
        }
    }
    
    func fetchAlbumTracks(id: String, name: String, artworkUrl: String) {
        guard !isLocalMode && isLoggedIn else { return }
        webService.performRequest(endpoint: "/v1/albums/\(id)/tracks?limit=50") { [weak self] result in
            if case .success(let data) = result {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let items = json["items"] as? [[String: Any]] {
                        let parsedTracks = items.compactMap { item -> SpotifyTrack? in
                            let artistName = ((item["artists"] as? [[String: Any]])?.first?["name"] as? String) ?? "Unknown Artist"
                            let artId = ((item["artists"] as? [[String: Any]])?.first?["id"] as? String)
                            return SpotifyTrack(
                                id: item["id"] as? String ?? "",
                                uri: item["uri"] as? String ?? "",
                                name: item["name"] as? String ?? "Unknown",
                                artist: artistName,
                                albumName: name,
                                artworkUrl: artworkUrl,
                                durationMs: item["duration_ms"] as? Int ?? 0,
                                artistId: artId
                            )
                        }
                        DispatchQueue.main.async {
                            self?.activePlaylistDetails = SpotifyPlaylistDetails(
                                id: id,
                                name: name,
                                artworkUrl: artworkUrl,
                                tracks: parsedTracks
                            )
                        }
                    }
                } catch {}
            }
        }
    }
    
    func addTrackToPlaylist(trackUri: String, playlistId: String) {
        guard !isLocalMode && isLoggedIn else { return }
        let body: [String: Any] = ["uris": [trackUri]]
        webService.performRequest(endpoint: "/v1/playlists/\(playlistId)/tracks", method: "POST", jsonBody: body) { [weak self] result in
            if case .success = result {
                DispatchQueue.main.async {
                    // Refresh current playlist if we are looking at it
                    if let activeDetails = self?.activePlaylistDetails, activeDetails.id == playlistId {
                        self?.fetchPlaylistTracks(id: playlistId, name: activeDetails.name, artworkUrl: activeDetails.artworkUrl)
                    }
                }
            }
        }
    }
    
    // MARK: - Local CSV Playback History & CSV Playlist Imports
    
    private func recordTrackToHistoryIfNeeded(trackName: String, artist: String, albumName: String, uri: String) {
        guard isPlaying else { return }
        
        let lowerTrack = trackName.lowercased()
        let lowerArtist = artist.lowercased()
        if lowerTrack.contains("no track playing") || lowerTrack.contains("spotify is closed") || lowerTrack.contains("not logged in") {
            return
        }
        if lowerArtist.contains("launch spotify to begin") || lowerArtist.contains("connect your account in settings") {
            return
        }
        
        let trackKey = "\(artist) - \(trackName)"
        guard trackKey != lastRecordedTrackKey else { return }
        lastRecordedTrackKey = trackKey
        
        // Trigger Audio Features API fetch
        fetchAudioFeatures(for: uri)
        
        appendToHistoryCSV(trackName: trackName, artist: artist, albumName: albumName, uri: uri)
    }
    
    private func appendToHistoryCSV(trackName: String, artist: String, albumName: String, uri: String) {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        guard let muzeebraDirectoryURL = documentsURL?.appendingPathComponent("Muzeebra") else { return }
        
        if !fileManager.fileExists(atPath: muzeebraDirectoryURL.path) {
            try? fileManager.createDirectory(at: muzeebraDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        }
        
        let csvURL = muzeebraDirectoryURL.appendingPathComponent("playback_history.csv")
        let fileExists = fileManager.fileExists(atPath: csvURL.path)
        
        var csvLine = ""
        if !fileExists {
            csvLine += "Timestamp,Track Name,Artist,Album,URI,Mode\n"
        }
        
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.timeZone = TimeZone.current
        let timestamp = dateFormatter.string(from: Date())
        
        let escapeCSV: (String) -> String = { val in
            let escaped = val.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        
        let mode = self.isLocalMode ? "Local" : "Cloud"
        csvLine += "\(timestamp),\(escapeCSV(trackName)),\(escapeCSV(artist)),\(escapeCSV(albumName)),\(escapeCSV(uri)),\(mode)\n"
        
        if let data = csvLine.data(using: .utf8) {
            if fileExists {
                if let fileHandle = try? FileHandle(forWritingTo: csvURL) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                }
            } else {
                try? data.write(to: csvURL)
            }
        }
        
        MuzeebraLogger.shared.log("[History] Logged track to CSV: \(artist) - \(trackName) (\(csvURL.path))")
    }
    
    func openLocalPlaylist(from url: URL) {
        do {
            let data = try Data(contentsOf: url)
            guard let csvString = String(data: data, encoding: .utf8) else { return }
            
            let rows = csvString.components(separatedBy: .newlines)
            guard !rows.isEmpty else { return }
            
            var parsedTracks: [SpotifyTrack] = []
            
            func parseCSVLine(_ line: String) -> [String] {
                var columns: [String] = []
                var currentColumn = ""
                var insideQuotes = false
                
                let chars = Array(line)
                var i = 0
                while i < chars.count {
                    let char = chars[i]
                    if char == "\"" {
                        insideQuotes.toggle()
                    } else if char == "," && !insideQuotes {
                        columns.append(currentColumn.trimmingCharacters(in: .whitespacesAndNewlines))
                        currentColumn = ""
                    } else {
                        currentColumn.append(char)
                    }
                    i += 1
                }
                columns.append(currentColumn.trimmingCharacters(in: .whitespacesAndNewlines))
                return columns
            }
            
            var headers: [String] = []
            var startIndex = 0
            
            if !rows.isEmpty {
                let firstLineCols = parseCSVLine(rows[0])
                let isHeader = firstLineCols.contains { col in
                    let lower = col.lowercased()
                    return lower == "track name" || lower == "artist" || lower == "title" || lower == "uri"
                }
                if isHeader {
                    headers = firstLineCols.map { $0.lowercased() }
                    startIndex = 1
                }
            }
            
            for index in startIndex..<rows.count {
                let row = rows[index]
                if row.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { continue }
                let cols = parseCSVLine(row)
                
                var trackName = "Unknown Track"
                var artistName = "Unknown Artist"
                var albumName = ""
                var trackUri = ""
                
                if !headers.isEmpty {
                    if let nameIdx = headers.firstIndex(where: { $0 == "track name" || $0 == "title" || $0 == "name" }), nameIdx < cols.count {
                        trackName = cols[nameIdx]
                    }
                    if let artistIdx = headers.firstIndex(where: { $0 == "artist" || $0 == "artist name" }), artistIdx < cols.count {
                        artistName = cols[artistIdx]
                    }
                    if let albumIdx = headers.firstIndex(where: { $0 == "album" || $0 == "album name" }), albumIdx < cols.count {
                        albumName = cols[albumIdx]
                    }
                    if let uriIdx = headers.firstIndex(where: { $0 == "uri" || $0 == "track id" || $0 == "id" }), uriIdx < cols.count {
                        trackUri = cols[uriIdx]
                    }
                } else {
                    if cols.count >= 2 {
                        let first = cols[0]
                        if first.contains("-") && first.contains("T") && first.count > 10 {
                            if cols.count >= 3 { trackName = cols[1] }
                            if cols.count >= 4 { artistName = cols[2] }
                            if cols.count >= 5 { albumName = cols[3] }
                            if cols.count >= 6 { trackUri = cols[4] }
                        } else {
                            trackName = cols[0]
                            artistName = cols[1]
                            if cols.count >= 3 { albumName = cols[2] }
                            if cols.count >= 4 { trackUri = cols[3] }
                        }
                    } else if cols.count == 1 {
                        trackName = cols[0]
                    }
                }
                
                let cleanQuote: (String) -> String = { val in
                    var s = val.trimmingCharacters(in: .whitespacesAndNewlines)
                    if s.hasPrefix("\"") && s.hasSuffix("\"") && s.count >= 2 {
                        s.removeFirst()
                        s.removeLast()
                    }
                    return s
                }
                
                trackName = cleanQuote(trackName)
                artistName = cleanQuote(artistName)
                albumName = cleanQuote(albumName)
                trackUri = cleanQuote(trackUri)
                
                let track = SpotifyTrack(
                    id: trackUri.components(separatedBy: ":").last ?? UUID().uuidString,
                    uri: trackUri,
                    name: trackName,
                    artist: artistName,
                    albumName: albumName,
                    artworkUrl: "",
                    durationMs: 0,
                    artistId: nil
                )
                parsedTracks.append(track)
            }
            
            let playlistName = url.deletingPathExtension().lastPathComponent
            
            DispatchQueue.main.async {
                self.activePlaylistDetails = SpotifyPlaylistDetails(
                    id: "local-\(UUID().uuidString)",
                    name: playlistName,
                    artworkUrl: "",
                    tracks: parsedTracks
                )
                self.selectedTab = "playlists"
            }
            
            MuzeebraLogger.shared.log("[Local Playlist] Loaded \(parsedTracks.count) tracks from local CSV: \(url.path)")
            
        } catch {
            MuzeebraLogger.shared.log("[Local Playlist] Error reading CSV: \(error.localizedDescription)")
        }
    }
    
    func openLocalPlaylistPicker() {
        DispatchQueue.main.async {
            let panel = NSOpenPanel()
            panel.allowsMultipleSelection = false
            panel.canChooseDirectories = false
            panel.canChooseFiles = true
            panel.allowedContentTypes = [.commaSeparatedText]
            
            if panel.runModal() == .OK {
                if let url = panel.url {
                    self.openLocalPlaylist(from: url)
                }
            }
        }
    }
    
    func toggleShuffle() {
        guard !isLocalMode && isLoggedIn else { return }
        let newState = !shuffleState
        self.shuffleState = newState
        
        let endpoint = "/v1/me/player/shuffle?state=\(newState)"
        webService.performRequest(endpoint: endpoint, method: "PUT") { [weak self] result in
            if case .success = result {
                DispatchQueue.main.async {
                    self?.triggerWebStateSync(delay: 0.8)
                }
            }
        }
    }
    
    private func parseTracksList(_ list: [[String: Any]]) -> [SpotifyTrack] {
        return list.map { t -> SpotifyTrack in
            let id = t["id"] as? String ?? ""
            let uri = t["uri"] as? String ?? ""
            let name = t["name"] as? String ?? ""
            var artistName = ""
            var artistId: String? = nil
            if let artists = t["artists"] as? [[String: Any]], let first = artists.first {
                artistName = first["name"] as? String ?? ""
                artistId = first["id"] as? String
            }
            var albName = ""
            var artUrl = ""
            if let album = t["album"] as? [String: Any] {
                albName = album["name"] as? String ?? ""
                if let images = album["images"] as? [[String: Any]], let firstImg = images.first {
                    artUrl = firstImg["url"] as? String ?? ""
                }
            }
            let duration = t["duration_ms"] as? Int ?? 0
            return SpotifyTrack(id: id, uri: uri, name: name, artist: artistName, albumName: albName, artworkUrl: artUrl, durationMs: duration, artistId: artistId)
        }
    }

    func fetchRecommendations() {
        guard !isLocalMode && isLoggedIn else { return }
        MuzeebraLogger.shared.log("[fetchRecommendations] Fetching top tracks from Spotify Web API...")
        
        // 1. Try fetching user's top tracks
        webService.performRequest(endpoint: "/v1/me/top/tracks?limit=10") { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let data):
                if !data.isEmpty {
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let rawItems = json["items"] as? [Any] {
                            let items = rawItems.compactMap { $0 as? [String: Any] }
                            if !items.isEmpty {
                                let parsed = self.parseTracksList(items)
                                MuzeebraLogger.shared.log("[fetchRecommendations] Successfully loaded \(parsed.count) top tracks.")
                                DispatchQueue.main.async {
                                    self.recommendedTracks = parsed
                                }
                                return
                            }
                        }
                    } catch {
                        MuzeebraLogger.shared.log("[fetchRecommendations] JSON parsing error for top tracks: \(error.localizedDescription)")
                    }
                }
                MuzeebraLogger.shared.log("[fetchRecommendations] Top tracks response was empty. Falling back to saved tracks.")
                self.fetchSavedTracksRecommendations()
            case .failure(let error):
                MuzeebraLogger.shared.log("[fetchRecommendations] Top tracks API request failed: \(error.localizedDescription). Falling back to saved tracks.")
                self.fetchSavedTracksRecommendations()
            }
        }
    }
    
    private func fetchSavedTracksRecommendations() {
        MuzeebraLogger.shared.log("[fetchRecommendations] Fetching saved tracks from Spotify Web API...")
        // 2. Try fetching user's saved/liked tracks
        webService.performRequest(endpoint: "/v1/me/tracks?limit=10") { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let data):
                if !data.isEmpty {
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let rawItems = json["items"] as? [Any] {
                            let items = rawItems.compactMap { $0 as? [String: Any] }
                            if !items.isEmpty {
                                let tracks = items.compactMap { $0["track"] as? [String: Any] }
                                let parsed = self.parseTracksList(tracks)
                                MuzeebraLogger.shared.log("[fetchRecommendations] Successfully loaded \(parsed.count) saved tracks.")
                                DispatchQueue.main.async {
                                    self.recommendedTracks = parsed
                                }
                                return
                            }
                        }
                    } catch {
                        MuzeebraLogger.shared.log("[fetchRecommendations] JSON parsing error for saved tracks: \(error.localizedDescription)")
                    }
                }
                MuzeebraLogger.shared.log("[fetchRecommendations] Saved tracks response was empty. Falling back to generic recommendations.")
                self.fetchGenericRecommendations()
            case .failure(let error):
                MuzeebraLogger.shared.log("[fetchRecommendations] Saved tracks API request failed: \(error.localizedDescription). Falling back to generic recommendations.")
                self.fetchGenericRecommendations()
            }
        }
    }
    
    private func fetchGenericRecommendations() {
        MuzeebraLogger.shared.log("[fetchRecommendations] Fetching generic pop recommendations from Spotify Search API...")
        // 3. Fallback to generic popular tracks search
        webService.performRequest(endpoint: "/v1/search?q=genre:pop&type=track&limit=10") { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let data):
                if !data.isEmpty {
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let tracksObj = json["tracks"] as? [String: Any],
                           let rawItems = tracksObj["items"] as? [Any] {
                            let items = rawItems.compactMap { $0 as? [String: Any] }
                            let parsed = self.parseTracksList(items)
                            MuzeebraLogger.shared.log("[fetchRecommendations] Successfully loaded \(parsed.count) generic pop tracks.")
                            DispatchQueue.main.async {
                                self.recommendedTracks = parsed
                            }
                        }
                    } catch {
                        MuzeebraLogger.shared.log("[fetchRecommendations] JSON parsing error for generic tracks: \(error.localizedDescription)")
                    }
                }
            case .failure(let error):
                MuzeebraLogger.shared.log("[fetchRecommendations] Generic search API request failed: \(error.localizedDescription).")
            }
        }
    }
    
    func fetchDiscoverContent() {
        guard !isLocalMode && isLoggedIn else { return }
        
        MuzeebraLogger.shared.log("[fetchDiscoverContent] Querying search for featured playlists...")
        // Use active Search queries as fallback for browse playlists and browse new releases
        webService.performRequest(endpoint: "/v1/search?q=Featured&type=playlist&limit=5") { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let data):
                if !data.isEmpty {
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let playlistsJson = json["playlists"] as? [String: Any],
                           let rawItems = playlistsJson["items"] as? [Any] {
                            
                            let items = rawItems.compactMap { $0 as? [String: Any] }
                            let parsedPlaylists = items.map { p -> SpotifyPlaylist in
                                let id = p["id"] as? String ?? ""
                                let name = p["name"] as? String ?? ""
                                var artUrl = ""
                                if let images = p["images"] as? [[String: Any]], let first = images.first {
                                    artUrl = first["url"] as? String ?? ""
                                }
                                let tracksInfo = p["items"] as? [String: Any] ?? p["tracks"] as? [String: Any]
                                let trackCount = tracksInfo?["total"] as? Int ?? 0
                                return SpotifyPlaylist(id: id, name: name, artworkUrl: artUrl, trackCount: trackCount)
                            }
                            
                            MuzeebraLogger.shared.log("[fetchDiscoverContent] Successfully loaded \(parsedPlaylists.count) featured playlists.")
                            DispatchQueue.main.async {
                                self.featuredPlaylists = parsedPlaylists
                            }
                        }
                    } catch {
                        MuzeebraLogger.shared.log("[fetchDiscoverContent] JSON parsing error for playlists: \(error.localizedDescription)")
                    }
                }
            case .failure(let error):
                MuzeebraLogger.shared.log("[fetchDiscoverContent] Playlists search API request failed: \(error.localizedDescription)")
            }
        }
        
        MuzeebraLogger.shared.log("[fetchDiscoverContent] Querying search for new releases...")
        webService.performRequest(endpoint: "/v1/search?q=tag:new&type=album&limit=5") { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let data):
                if !data.isEmpty {
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let albumsJson = json["albums"] as? [String: Any],
                           let rawItems = albumsJson["items"] as? [Any] {
                            
                            let items = rawItems.compactMap { $0 as? [String: Any] }
                            let parsedAlbums = items.map { a -> SpotifyAlbum in
                                let id = a["id"] as? String ?? ""
                                let name = a["name"] as? String ?? ""
                                let uri = a["uri"] as? String ?? ""
                                var artistName = ""
                                if let artists = a["artists"] as? [[String: Any]], let first = artists.first {
                                    artistName = first["name"] as? String ?? ""
                                }
                                var artUrl = ""
                                if let images = a["images"] as? [[String: Any]], let first = images.first {
                                    artUrl = first["url"] as? String ?? ""
                                }
                                return SpotifyAlbum(id: id, name: name, artist: artistName, artworkUrl: artUrl, uri: uri)
                            }
                            
                            MuzeebraLogger.shared.log("[fetchDiscoverContent] Successfully loaded \(parsedAlbums.count) new releases.")
                            DispatchQueue.main.async {
                                self.newReleases = parsedAlbums
                            }
                        }
                    } catch {
                        MuzeebraLogger.shared.log("[fetchDiscoverContent] JSON parsing error for new releases: \(error.localizedDescription)")
                    }
                }
            case .failure(let error):
                MuzeebraLogger.shared.log("[fetchDiscoverContent] New releases search API request failed: \(error.localizedDescription)")
            }
        }
    }
    
    private func cleanTrackName(_ name: String) -> String {
        var cleaned = name
        let patterns = [
            "\\s*\\((feat|with|featuring|prod|cover|remix)\\.?\\s+[^)]+\\)",
            "\\s*\\[(feat|with|featuring|prod|cover|remix)\\.?\\s+[^]]+\\]",
            "\\s*-\\s*(feat|with|featuring|prod|cover|remix)\\.?\\s+.*$",
            "\\s*-\\s*Radio\\s+Edit",
            "\\s*-\\s*Single\\s+Version",
            "\\s*-\\s*Remix",
            "\\s*-\\s*Remastered",
            "\\s*-\\s*Live",
            "\\s*\\((Live|Remastered|Radio\\s+Edit|Remix)\\)"
        ]
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                let range = NSRange(cleaned.startIndex..., in: cleaned)
                cleaned = regex.stringByReplacingMatches(in: cleaned, options: [], range: range, withTemplate: "")
            }
        }
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? name : cleaned
    }
    
    private func cleanArtistName(_ name: String) -> String {
        var cleaned = name
        let separators = [",", " feat.", " featuring", " & ", " + "]
        for sep in separators {
            if let firstPart = cleaned.components(separatedBy: sep).first {
                cleaned = firstPart
            }
        }
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? name : cleaned
    }

    func fetchLyrics(artistName: String, trackName: String) {
        let trimmedArtist = artistName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTrack = trackName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedArtist.isEmpty && !trimmedTrack.isEmpty else { return }
        
        // Skip placeholders
        guard trimmedArtist != "Unknown" && trimmedTrack != "Unknown" else { return }
        guard trimmedArtist != "Launch Spotify to begin" && trimmedTrack != "Spotify is Closed" else { return }
        guard trimmedArtist != "Not Logged In" && trimmedTrack != "Connect your account in Settings" else { return }
        
        let key = "\(trimmedArtist) - \(trimmedTrack)"
        guard key != lastFetchedTrackAndArtist else { return }
        lastFetchedTrackAndArtist = key
        
        self.isLyricsLoading = true
        self.lyricsText = ""
        self.lyricsSyncedLines = []
        
        MuzeebraLogger.shared.log("[fetchLyrics] Starting lookup for: \(key)")
        
        let exactQuery = "\(trimmedArtist) \(trimmedTrack)"
        performLyricsSearch(query: exactQuery) { [weak self] success in
            if success {
                MuzeebraLogger.shared.log("[fetchLyrics] Exact query succeeded.")
                return
            }
            
            // Try fallback query with cleaned names
            let cleanedArtist = self?.cleanArtistName(trimmedArtist) ?? trimmedArtist
            let cleanedTrack = self?.cleanTrackName(trimmedTrack) ?? trimmedTrack
            let fallbackQuery = "\(cleanedArtist) \(cleanedTrack)"
            
            if fallbackQuery == exactQuery {
                MuzeebraLogger.shared.log("[fetchLyrics] Exact query failed and clean query is identical. Giving up.")
                DispatchQueue.main.async {
                    self?.isLyricsLoading = false
                }
                return
            }
            
            MuzeebraLogger.shared.log("[fetchLyrics] Exact query failed. Trying fallback query: \(fallbackQuery)")
            self?.performLyricsSearch(query: fallbackQuery) { success in
                if success {
                    MuzeebraLogger.shared.log("[fetchLyrics] Fallback query succeeded.")
                } else {
                    MuzeebraLogger.shared.log("[fetchLyrics] Fallback query failed. No lyrics found.")
                    DispatchQueue.main.async {
                        self?.isLyricsLoading = false
                    }
                }
            }
        }
    }
    
    private func performLyricsSearch(query: String, completion: @escaping (Bool) -> Void) {
        var components = URLComponents(string: "https://lrclib.net/api/search")
        components?.queryItems = [URLQueryItem(name: "q", value: query)]
        
        guard let url = components?.url else {
            completion(false)
            return
        }
        
        MuzeebraLogger.shared.log("[fetchLyrics] HTTP GET: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.setValue("Muzeebra/1.0.0 (https://github.com/portfolio/muzeebra)", forHTTPHeaderField: "User-Agent")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                MuzeebraLogger.shared.log("[fetchLyrics] Request error: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                MuzeebraLogger.shared.log("[fetchLyrics] Invalid response object")
                completion(false)
                return
            }
            
            MuzeebraLogger.shared.log("[fetchLyrics] Response status: \(httpResponse.statusCode)")
            
            guard httpResponse.statusCode == 200, let data = data else {
                completion(false)
                return
            }
            
            do {
                if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]], let firstMatch = jsonArray.first {
                    DispatchQueue.main.async {
                        if let plain = firstMatch["plainLyrics"] as? String {
                            self?.lyricsText = plain
                        }
                        if let synced = firstMatch["syncedLyrics"] as? String {
                            self?.parseSyncedLyrics(synced)
                        }
                        self?.isLyricsLoading = false
                    }
                    completion(true)
                } else {
                    MuzeebraLogger.shared.log("[fetchLyrics] Response JSON contained no matches")
                    completion(false)
                }
            } catch {
                MuzeebraLogger.shared.log("[fetchLyrics] JSON parse error: \(error.localizedDescription)")
                completion(false)
            }
        }.resume()
    }
    
    private func parseSyncedLyrics(_ lrc: String) {
        var lines: [SyncedLyricLine] = []
        let rawLines = lrc.components(separatedBy: .newlines)
        for line in rawLines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.hasPrefix("[") else { continue }
            let parts = trimmed.split(separator: "]", maxSplits: 1)
            guard parts.count == 2 else { continue }
            
            let timeStr = parts[0].dropFirst() // remove "["
            let content = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
            
            let timeParts = timeStr.split(separator: ":")
            if timeParts.count == 2 {
                if let mins = Double(timeParts[0]), let secs = Double(timeParts[1]) {
                    let timeMs = (mins * 60 + secs) * 1000.0
                    lines.append(SyncedLyricLine(timeMs: timeMs, text: content))
                }
            }
        }
        self.lyricsSyncedLines = lines
    }
    
    func fetchArtistDetails(id: String) {
        guard !isLocalMode && isLoggedIn && !id.isEmpty else { return }
        
        let dispatchGroup = DispatchGroup()
        
        var name = ""
        var artworkUrl = ""
        var genres: [String] = []
        var followersCount = 0
        var topTracks: [SpotifyTrack] = []
        var albums: [SpotifyAlbum] = []
        
        // 1. Fetch Artist Profile Metadata
        dispatchGroup.enter()
        webService.performRequest(endpoint: "/v1/artists/\(id)") { result in
            defer { dispatchGroup.leave() }
            if case .success(let data) = result {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    name = json["name"] as? String ?? ""
                    genres = json["genres"] as? [String] ?? []
                    followersCount = (json["followers"] as? [String: Any])?["total"] as? Int ?? 0
                    if let images = json["images"] as? [[String: Any]], let first = images.first {
                        artworkUrl = first["url"] as? String ?? ""
                    }
                }
            }
        }
        
        // 2. Fetch Artist Top Tracks
        dispatchGroup.enter()
        webService.performRequest(endpoint: "/v1/artists/\(id)/top-tracks?market=from_token") { result in
            defer { dispatchGroup.leave() }
            if case .success(let data) = result {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let tracksJson = json["tracks"] as? [[String: Any]] {
                    topTracks = tracksJson.prefix(5).map { t -> SpotifyTrack in
                        var albumArt = ""
                        if let album = t["album"] as? [String: Any],
                           let images = album["images"] as? [[String: Any]],
                           let firstImg = images.first {
                            albumArt = firstImg["url"] as? String ?? ""
                        }
                        let artistName = ((t["artists"] as? [[String: Any]])?.first?["name"] as? String) ?? "Unknown Artist"
                        let artId = ((t["artists"] as? [[String: Any]])?.first?["id"] as? String)
                        return SpotifyTrack(
                            id: t["id"] as? String ?? "",
                            uri: t["uri"] as? String ?? "",
                            name: t["name"] as? String ?? "Unknown",
                            artist: artistName,
                            albumName: (t["album"] as? [String: Any])?["name"] as? String ?? "",
                            artworkUrl: albumArt,
                            durationMs: t["duration_ms"] as? Int ?? 0,
                            artistId: artId
                        )
                    }
                }
            }
        }
        
        // 3. Fetch Artist Albums
        dispatchGroup.enter()
        webService.performRequest(endpoint: "/v1/artists/\(id)/albums?limit=10") { result in
            defer { dispatchGroup.leave() }
            if case .success(let data) = result {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let items = json["items"] as? [[String: Any]] {
                    albums = items.map { a -> SpotifyAlbum in
                        let id = a["id"] as? String ?? ""
                        let name = a["name"] as? String ?? ""
                        let uri = a["uri"] as? String ?? ""
                        var artistName = ""
                        if let artists = a["artists"] as? [[String: Any]], let first = artists.first {
                            artistName = first["name"] as? String ?? ""
                        }
                        var artUrl = ""
                        if let images = a["images"] as? [[String: Any]], let first = images.first {
                            artUrl = first["url"] as? String ?? ""
                        }
                        return SpotifyAlbum(id: id, name: name, artist: artistName, artworkUrl: artUrl, uri: uri)
                    }
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) { [weak self] in
            guard !name.isEmpty else { return }
            self?.activeArtistDetails = SpotifyArtistDetails(
                id: id,
                name: name,
                artworkUrl: artworkUrl,
                genres: genres,
                followersCount: followersCount,
                topTracks: topTracks,
                albums: albums
            )
        }
    }
    
    func playContext(uri: String) {
        if uri.hasPrefix("spotify:playlist:local-") || uri.contains("local-") {
            if let tracks = activePlaylistDetails?.tracks, !tracks.isEmpty {
                if let firstTrack = tracks.first {
                    playTrack(uri: firstTrack.uri)
                }
            }
        } else if isLocalMode {
            localService.playTrack(uri: uri)
        } else {
            let body: [String: Any] = ["context_uri": uri]
            webService.performRequest(endpoint: "/v1/me/player/play", method: "PUT", jsonBody: body) { [weak self] result in
                if case .success = result {
                    DispatchQueue.main.async { self?.triggerWebStateSync(delay: 0.8) }
                }
            }
        }
    }
    
    func playTrack(uri: String) {
        if isLocalMode {
            localService.playTrack(uri: uri)
        } else {
            let body: [String: Any] = ["uris": [uri]]
            webService.performRequest(endpoint: "/v1/me/player/play", method: "PUT", jsonBody: body) { [weak self] result in
                if case .success = result {
                    DispatchQueue.main.async { self?.triggerWebStateSync(delay: 0.8) }
                }
            }
        }
    }
    
    private var searchWorkItem: DispatchWorkItem?
    
    private func performSearch() {
        searchWorkItem?.cancel()
        
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            self.searchResults = []
            return
        }
        
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            self.webService.performRequest(endpoint: "/v1/search?q=\(encodedQuery)&type=track&limit=10") { result in
                switch result {
                case .failure:
                    break
                case .success(let data):
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let tracksJson = json["tracks"] as? [String: Any],
                           let items = tracksJson["items"] as? [[String: Any]] {
                            let parsedTracks = items.map { t -> SpotifyTrack in
                                var albumArt = ""
                                if let album = t["album"] as? [String: Any],
                                   let images = album["images"] as? [[String: Any]],
                                   let firstImg = images.first {
                                    albumArt = firstImg["url"] as? String ?? ""
                                }
                                let artistName = ((t["artists"] as? [[String: Any]])?.first?["name"] as? String) ?? "Unknown Artist"
                                let artId = ((t["artists"] as? [[String: Any]])?.first?["id"] as? String)
                                return SpotifyTrack(
                                    id: t["id"] as? String ?? "",
                                    uri: t["uri"] as? String ?? "",
                                    name: t["name"] as? String ?? "Unknown",
                                    artist: artistName,
                                    albumName: (t["album"] as? [String: Any])?["name"] as? String ?? "",
                                    artworkUrl: albumArt,
                                    durationMs: t["duration_ms"] as? Int ?? 0,
                                    artistId: artId
                                )
                            }
                            DispatchQueue.main.async {
                                self.searchResults = parsedTracks
                            }
                        }
                    } catch {}
                }
            }
        }
        
        searchWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: workItem)
    }
    
    // Performance stats updater
    private func updatePerformanceStats() {
        // Read memory basic info
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let kerr = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        if kerr == KERN_SUCCESS {
            self.memoryUsage = info.resident_size
        }
        
        // Count total API requests
        self.apiCallCount = webService.apiRequestsCount
        
        // Simple CPU usage check
        self.cpuUsage = isPlaying ? (lowPowerMode ? 0.1 : 0.8) : 0.02
    }
}

// Models
struct SpotifyDevice: Identifiable {
    let id: String
    let name: String
    let type: String
    let isActive: Bool
}

struct SpotifyTrack: Identifiable, Codable {
    let id: String
    let uri: String
    let name: String
    let artist: String
    let albumName: String
    let artworkUrl: String
    let durationMs: Int
    let artistId: String?
}

struct SpotifyPlaylist: Identifiable {
    let id: String
    let name: String
    let artworkUrl: String
    let trackCount: Int
}

struct SpotifyPlaylistDetails: Identifiable, Codable {
    let id: String
    let name: String
    let artworkUrl: String
    let tracks: [SpotifyTrack]
}

struct SpotifyAlbum: Identifiable {
    let id: String
    let name: String
    let artist: String
    let artworkUrl: String
    let uri: String
}

struct SyncedLyricLine: Identifiable, Equatable {
    let id = UUID()
    let timeMs: Double
    let text: String
}

struct SpotifyArtistDetails: Identifiable {
    let id: String
    let name: String
    let artworkUrl: String
    let genres: [String]
    let followersCount: Int
    let topTracks: [SpotifyTrack]
    let albums: [SpotifyAlbum]
}

