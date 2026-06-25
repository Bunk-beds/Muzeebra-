import AppKit
import WebKit

class SpotifyWebPlayerWindowController: NSObject {
    static let shared = SpotifyWebPlayerWindowController()
    
    private var window: NSWindow?
    private var webView: WKWebView?
    private var store: SpotifyStore?
    
    func setup(with store: SpotifyStore) {
        self.store = store
        
        // Only run if we are in Web mode and logged in
        guard !store.isLocalMode && store.isLoggedIn else {
            closeWindow()
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.window == nil {
                self.createWindow()
            }
        }
    }
    
    private func createWindow() {
        // Create a 1x1 window at screen coordinate (0, 0)
        let contentRect = NSRect(x: 0, y: 0, width: 1, height: 1)
        let styleMask: NSWindow.StyleMask = [.borderless]
        
        let newWindow = NSWindow(
            contentRect: contentRect,
            styleMask: styleMask,
            backing: .buffered,
            defer: false
        )
        
        newWindow.title = "Muzeebra Engine"
        newWindow.isOpaque = false
        newWindow.backgroundColor = .clear
        newWindow.ignoresMouseEvents = true
        newWindow.level = .floating // Keep it on screen so it stays active
        newWindow.collectionBehavior = [.canJoinAllSpaces, .ignoresCycle]
        
        // Create WKWebView
        let configuration = WKWebViewConfiguration()
        configuration.mediaTypesRequiringUserActionForPlayback = [] // Allow autoplay
        
        // Inject Equalizer Web Audio API Hook into all frames at document start
        let eqScriptSource = #"""
        (function() {
            if (window.__muzeebra_eq_hooked) return;
            window.__muzeebra_eq_hooked = true;

            console.log("Muzeebra: AudioContext EQ hook injected in " + window.location.href);

            const originalConnect = AudioNode.prototype.connect;
            const activeContexts = new Set();
            
            let eqEnabled = false;
            let eqBands = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
            let eqPreamp = 0;
            
            const frequencies = [32, 64, 125, 250, 500, 1000, 2000, 4000, 8000, 16000];

            function setupEQFilters(context) {
                if (context.__eqFilters) return;
                
                console.log("Muzeebra: Setting up EQ filters for context");
                
                const preampNode = context.createGain();
                preampNode.gain.value = Math.pow(10, (eqEnabled ? eqPreamp : 0) / 20.0);
                
                const filters = frequencies.map((freq, index) => {
                    const filter = context.createBiquadFilter();
                    if (index === 0) {
                        filter.type = 'lowshelf';
                    } else if (index === frequencies.length - 1) {
                        filter.type = 'highshelf';
                    } else {
                        filter.type = 'peaking';
                    }
                    filter.frequency.value = freq;
                    filter.Q.value = 1.0;
                    filter.gain.value = eqEnabled ? eqBands[index] : 0.0;
                    return filter;
                });
                
                originalConnect.call(preampNode, filters[0]);
                for (let i = 0; i < filters.length - 1; i++) {
                    originalConnect.call(filters[i], filters[i+1]);
                }
                originalConnect.call(filters[filters.length - 1], context.destination);
                
                context.__eqPreampNode = preampNode;
                context.__eqFilters = filters;
                activeContexts.add(context);
            }
            
            AudioNode.prototype.connect = function(destination, output, input) {
                if (destination === this.context.destination) {
                    const context = this.context;
                    
                    if (this === context.__eqPreampNode || 
                        (context.__eqFilters && context.__eqFilters.includes(this))) {
                        return originalConnect.apply(this, arguments);
                    }
                    
                    setupEQFilters(context);
                    return originalConnect.call(this, context.__eqPreampNode, output, input);
                }
                return originalConnect.apply(this, arguments);
            };
            
            window.updateEqualizer = function(enabled, bands, preamp) {
                eqEnabled = enabled;
                eqBands = bands;
                eqPreamp = preamp;
                
                for (const context of activeContexts) {
                    try {
                        if (context.state === 'closed') {
                            activeContexts.delete(context);
                            continue;
                        }
                        if (context.__eqPreampNode) {
                            const preampDb = enabled ? preamp : 0.0;
                            context.__eqPreampNode.gain.setValueAtTime(Math.pow(10, preampDb / 20.0), context.currentTime);
                        }
                        if (context.__eqFilters) {
                            for (let i = 0; i < context.__eqFilters.length; i++) {
                                context.__eqFilters[i].gain.setValueAtTime(enabled ? bands[i] : 0.0, context.currentTime);
                            }
                        }
                    } catch (e) {
                        console.error("Muzeebra EQ update failed:", e);
                    }
                }
                
                if (window === window.top) {
                    propagateToFrames(window, enabled, bands, preamp);
                }
            };
            
            function propagateToFrames(win, enabled, bands, preamp) {
                const iframes = win.document.getElementsByTagName('iframe');
                for (let i = 0; i < iframes.length; i++) {
                    try {
                        const childWin = iframes[i].contentWindow;
                        if (childWin && childWin.updateEqualizer) {
                            childWin.updateEqualizer(enabled, bands, preamp);
                        }
                    } catch (e) {
                        try {
                            iframes[i].contentWindow.postMessage({
                                type: "muzeebra_eq_update",
                                enabled: enabled,
                                bands: bands,
                                preamp: preamp
                            }, "*");
                        } catch (err) {}
                    }
                }
            }

            window.addEventListener("message", function(event) {
                if (event.data && event.data.type === "muzeebra_eq_update") {
                    window.updateEqualizer(event.data.enabled, event.data.bands, event.data.preamp);
                } else if (event.data && event.data.type === "muzeebra_eq_request") {
                    if (window === window.top) {
                        event.source.postMessage({
                            type: "muzeebra_eq_update",
                            enabled: eqEnabled,
                            bands: eqBands,
                            preamp: eqPreamp
                        }, "*");
                    }
                }
            });

            if (window !== window.top) {
                window.parent.postMessage({ type: "muzeebra_eq_request" }, "*");
            }
        })();
        """#
        
        let userScript = WKUserScript(source: eqScriptSource, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        configuration.userContentController.addUserScript(userScript)
        
        // Add message handler
        let coordinator = WebPlayerCoordinator(self)
        configuration.userContentController.add(coordinator, name: "muzeebra")
        
        let newWebView = WKWebView(frame: contentRect, configuration: configuration)
        newWebView.setValue(false, forKey: "drawsBackground") // Transparent background
        
        newWindow.contentView = newWebView
        
        self.window = newWindow
        self.webView = newWebView
        
        // Load the player HTML page
        loadPlayerHTML()
        
        // Show the window but don't activate/focus it
        newWindow.orderFront(nil)
        
        MuzeebraLogger.shared.log("Created 1x1 background playback window")
    }
    
    func updateToken(_ token: String) {
        guard let webView = webView else { return }
        let js = "updateToken('\(token)');"
        DispatchQueue.main.async {
            webView.evaluateJavaScript(js, completionHandler: nil)
        }
    }
    
    func setVolume(_ vol: Double) {
        guard let webView = webView else { return }
        let js = "if (player) { player.setVolume(\(vol)); }"
        DispatchQueue.main.async {
            webView.evaluateJavaScript(js, completionHandler: nil)
        }
    }
    
    func togglePlay() {
        guard let webView = webView else { return }
        let js = "if (player) { player.togglePlay(); }"
        DispatchQueue.main.async {
            webView.evaluateJavaScript(js, completionHandler: nil)
        }
    }
    
    func nextTrack() {
        guard let webView = webView else { return }
        let js = "if (player) { player.nextTrack(); }"
        DispatchQueue.main.async {
            webView.evaluateJavaScript(js, completionHandler: nil)
        }
    }
    
    func previousTrack() {
        guard let webView = webView else { return }
        let js = "if (player) { player.previousTrack(); }"
        DispatchQueue.main.async {
            webView.evaluateJavaScript(js, completionHandler: nil)
        }
    }
    
    func seek(to ms: Int) {
        guard let webView = webView else { return }
        let js = "if (player) { player.seek(\(ms)); }"
        DispatchQueue.main.async {
            webView.evaluateJavaScript(js, completionHandler: nil)
        }
    }
    
    func updateEqualizer(isEnabled: Bool, bands: [Double], preamp: Double) {
        guard let webView = webView else { return }
        let bandsString = bands.map { String($0) }.joined(separator: ",")
        let js = "if (window.updateEqualizer) { window.updateEqualizer(\(isEnabled), [\(bandsString)], \(preamp)); }"
        DispatchQueue.main.async {
            webView.evaluateJavaScript(js, completionHandler: nil)
        }
    }
    
    func updateMediaSession(title: String, artist: String, album: String, artworkUrl: String, positionMs: Double = 0.0, durationMs: Int = 0, isPlaying: Bool = false) {
        guard let webView = webView else { return }
        let escapedTitle = title.replacingOccurrences(of: "'", with: "\\'")
        let escapedArtist = artist.replacingOccurrences(of: "'", with: "\\'")
        let escapedAlbum = album.replacingOccurrences(of: "'", with: "\\'")
        let escapedArtwork = artworkUrl.replacingOccurrences(of: "'", with: "\\'")
        let rate = isPlaying ? 1.0 : 0.0
        
        let js = "updateMediaSession('\(escapedTitle)', '\(escapedArtist)', '\(escapedAlbum)', '\(escapedArtwork)', \(positionMs), \(durationMs), \(rate));"
        DispatchQueue.main.async {
            webView.evaluateJavaScript(js, completionHandler: nil)
        }
    }
    
    func closeWindow() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.webView?.configuration.userContentController.removeScriptMessageHandler(forName: "muzeebra")
            self.webView = nil
            self.window?.close()
            self.window = nil
            MuzeebraLogger.shared.log("Closed 1x1 background playback window")
        }
    }
    
    private func loadPlayerHTML() {
        let htmlString = """
        <!DOCTYPE html>
        <html>
        <head>
            <title>Muzeebra</title>
            <script src="https://sdk.scdn.co/spotify-player.js"></script>
            <script>
                let player = null;
                let activeToken = "";
                let currentTrackInfo = {
                    title: 'Muzeebra',
                    artist: 'Muzeebra Web Player',
                    album: 'Muzeebra',
                    artworkUrl: '',
                    positionMs: 0,
                    durationMs: 0,
                    playbackRate: 0.0
                };

                // Hook mediaSession API on a given window context to block Spotify's SDK default titles
                function hookMediaSession(win) {
                    try {
                        if (!win || !win.navigator) return;
                        
                        // Hook MediaMetadata constructor in this frame/window context
                        if (win.MediaMetadata && !win.MediaMetadata.isHooked) {
                            const OriginalMediaMetadata = win.MediaMetadata;
                            const HookedMediaMetadata = function(data) {
                                if (data && data.title === "Spotify Embedded Player") {
                                    data.title = currentTrackInfo.title;
                                    data.artist = currentTrackInfo.artist;
                                    data.album = currentTrackInfo.album;
                                    if (currentTrackInfo.artworkUrl) {
                                        data.artwork = [{ src: currentTrackInfo.artworkUrl, sizes: '512x512', type: 'image/jpeg' }];
                                    }
                                }
                                return new OriginalMediaMetadata(data);
                            };
                            HookedMediaMetadata.isHooked = true;
                            win.MediaMetadata = HookedMediaMetadata;
                        }

                        // Hook the metadata setter on navigator.mediaSession
                        if (win.navigator.mediaSession) {
                            const mediaSession = win.navigator.mediaSession;
                            let originalMetadata = mediaSession.metadata;
                            if (!Object.getOwnPropertyDescriptor(mediaSession, 'metadata')?.set) {
                                Object.defineProperty(mediaSession, 'metadata', {
                                    get: function() {
                                        return originalMetadata;
                                    },
                                    set: function(val) {
                                        if (val && val.title === "Spotify Embedded Player") {
                                            val = new win.MediaMetadata({
                                                title: currentTrackInfo.title,
                                                artist: currentTrackInfo.artist,
                                                album: currentTrackInfo.album,
                                                artwork: currentTrackInfo.artworkUrl ? [{ src: currentTrackInfo.artworkUrl, sizes: '512x512', type: 'image/jpeg' }] : []
                                            });
                                        }
                                        originalMetadata = val;
                                    },
                                    configurable: true
                                });
                            }
                        }
                    } catch (e) {
                        console.error("Hook failed: ", e);
                    }
                }

                // Initial hook of parent window
                hookMediaSession(window);

                // Observe dynamic iframes to apply the hook immediately when they load
                const observer = new MutationObserver((mutations) => {
                    mutations.forEach((mutation) => {
                        mutation.addedNodes.forEach((node) => {
                            if (node.tagName === 'IFRAME') {
                                node.addEventListener('load', () => {
                                    hookMediaSession(node.contentWindow);
                                    updateMediaSession(
                                        currentTrackInfo.title,
                                        currentTrackInfo.artist,
                                        currentTrackInfo.album,
                                        currentTrackInfo.artworkUrl,
                                        currentTrackInfo.positionMs,
                                        currentTrackInfo.durationMs,
                                        currentTrackInfo.playbackRate
                                    );
                                });
                                hookMediaSession(node.contentWindow);
                            }
                        });
                    });
                });
                
                if (document.documentElement) {
                    observer.observe(document.documentElement, { childList: true, subtree: true });
                } else {
                    window.addEventListener('load', () => {
                        observer.observe(document.body, { childList: true, subtree: true });
                    });
                }

                function updateMediaSession(title, artist, album, artworkUrl, positionMs, durationMs, playbackRate) {
                    currentTrackInfo = {
                        title: title || 'Muzeebra',
                        artist: artist || 'Muzeebra Web Player',
                        album: album || 'Muzeebra',
                        artworkUrl: artworkUrl || '',
                        positionMs: positionMs || 0,
                        durationMs: durationMs || 0,
                        playbackRate: playbackRate || 0.0
                    };

                    const metadata = {
                        title: currentTrackInfo.title,
                        artist: currentTrackInfo.artist,
                        album: currentTrackInfo.album,
                        artwork: currentTrackInfo.artworkUrl ? [{ src: currentTrackInfo.artworkUrl, sizes: '512x512', type: 'image/jpeg' }] : []
                    };

                    if ('mediaSession' in navigator) {
                        navigator.mediaSession.metadata = new MediaMetadata(metadata);
                        
                        if (typeof positionMs !== 'undefined' && typeof durationMs !== 'undefined' && durationMs > 0) {
                            const posSec = positionMs / 1000.0;
                            const durSec = durationMs / 1000.0;
                            const rate = typeof playbackRate !== 'undefined' ? playbackRate : 1.0;
                            const clampedPos = Math.max(0, Math.min(posSec, durSec));
                            try {
                                navigator.mediaSession.setPositionState({
                                    duration: durSec,
                                    playbackRate: rate,
                                    position: clampedPos
                                });
                            } catch (e) {}
                        }
                    }

                    // Propagate to all same-origin iframes
                    const iframes = document.getElementsByTagName('iframe');
                    for (let i = 0; i < iframes.length; i++) {
                        try {
                            const iframe = iframes[i];
                            if (iframe.contentWindow) {
                                const iframeMediaSession = iframe.contentWindow.navigator && iframe.contentWindow.navigator.mediaSession;
                                if (iframeMediaSession) {
                                    iframeMediaSession.metadata = new iframe.contentWindow.MediaMetadata(metadata);
                                    
                                    if (typeof positionMs !== 'undefined' && typeof durationMs !== 'undefined' && durationMs > 0) {
                                        const posSec = positionMs / 1000.0;
                                        const durSec = durationMs / 1000.0;
                                        const rate = typeof playbackRate !== 'undefined' ? playbackRate : 1.0;
                                        const clampedPos = Math.max(0, Math.min(posSec, durSec));
                                        try {
                                            iframeMediaSession.setPositionState({
                                                duration: durSec,
                                                playbackRate: rate,
                                                position: clampedPos
                                            });
                                        } catch (e) {}
                                    }
                                }
                                if (iframe.contentDocument) {
                                    iframe.contentDocument.title = currentTrackInfo.title;
                                }
                            }
                        } catch (e) {}
                    }

                    document.title = currentTrackInfo.title;
                }

                window.onSpotifyWebPlaybackSDKReady = () => {
                    window.webkit.messageHandlers.muzeebra.postMessage({
                        event: "sdk_ready"
                    });
                };

                function updateToken(token) {
                    if (activeToken === token) return;
                    activeToken = token;
                    
                    if (player) {
                        player.disconnect();
                    }

                    player = new Spotify.Player({
                        name: 'Muzeebra Web Player',
                        getOAuthToken: cb => { cb(token); },
                        volume: 0.5,
                        enableMediaSession: true
                    });

                    player.addListener('ready', ({ device_id }) => {
                        window.webkit.messageHandlers.muzeebra.postMessage({
                            event: "ready",
                            deviceId: device_id
                        });
                    });

                    player.addListener('player_state_changed', state => {
                        if (state && state.track_window && state.track_window.current_track) {
                            const track = state.track_window.current_track;
                            const title = track.name;
                            const artistName = track.artists[0]?.name || "Unknown Artist";
                            const albName = track.album.name || "Unknown Album";
                            const artUrl = track.album.images[0]?.url || "";
                            
                            window.webkit.messageHandlers.muzeebra.postMessage({
                                event: "player_state_changed",
                                state: {
                                    trackName: title,
                                    artist: artistName,
                                    albumName: albName,
                                    artworkUrl: artUrl,
                                    isPlaying: !state.paused,
                                    positionMs: state.position,
                                    durationMs: state.duration
                                }
                            });
                            
                            updateMediaSession(title, artistName, albName, artUrl, state.position, state.duration, state.paused ? 0.0 : 1.0);
                        } else {
                            updateMediaSession('Muzeebra', 'Muzeebra Web Player', 'Muzeebra', '', 0, 0, 0.0);
                        }
                    });

                    player.addListener('initialization_error', ({ message }) => { sendError('initialization_error', message); });
                    player.addListener('authentication_error', ({ message }) => { sendError('authentication_error', message); });
                    player.addListener('account_error', ({ message }) => { sendError('account_error', message); });
                    player.addListener('playback_error', ({ message }) => { sendError('playback_error', message); });

                    player.connect();
                }

                function sendError(event, message) {
                    window.webkit.messageHandlers.muzeebra.postMessage({
                        event: event,
                        message: message
                    });
                }
            </script>
        </head>
        <body style="background:transparent;margin:0;">
            <p style="color:white;font-size:10px;">Muzeebra Engine</p>
        </body>
        </html>
        """
        webView?.loadHTMLString(htmlString, baseURL: URL(string: "https://sdk.scdn.co/"))
        
        // Seed token if we already have one
        if let token = store?.accessToken {
            updateToken(token)
        }
    }
    
    private class WebPlayerCoordinator: NSObject, WKScriptMessageHandler {
        weak var controller: SpotifyWebPlayerWindowController?
        
        init(_ controller: SpotifyWebPlayerWindowController) {
            self.controller = controller
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard let controller = controller, let store = controller.store else { return }
            if let body = message.body as? [String: Any], let event = body["event"] as? String {
                switch event {
                case "ready":
                    if let deviceId = body["deviceId"] as? String {
                        MuzeebraLogger.shared.log("Background SDK Player Ready with Device ID: \(deviceId)")
                        DispatchQueue.main.async {
                            store.localPlayerDeviceId = deviceId
                            store.activeDeviceId = deviceId
                            store.transferPlayback(to: deviceId)
                            store.fetchWebDevices()
                        }
                    }
                case "sdk_ready":
                    MuzeebraLogger.shared.log("Spotify Web Playback SDK loaded inside background WKWebView")
                case "playback_error":
                    if let err = body["message"] as? String {
                        MuzeebraLogger.shared.log("Background SDK Player playback error: \(err)")
                    }
                case "authentication_error":
                    if let err = body["message"] as? String {
                        MuzeebraLogger.shared.log("Background SDK Player authentication error: \(err)")
                    }
                case "account_error":
                    if let err = body["message"] as? String {
                        MuzeebraLogger.shared.log("Background SDK Player account error (Premium required for SDK): \(err)")
                    }
                case "player_state_changed":
                    if let state = body["state"] as? [String: Any] {
                        DispatchQueue.main.async {
                            store.updateFromWebPlayerState(state)
                        }
                    }
                default:
                    break
                }
            }
        }
    }
}
