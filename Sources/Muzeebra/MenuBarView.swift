import SwiftUI

extension Color {
    static let winampOrange = Color(red: 1.0, green: 0.28, blue: 0.12)
    static let winampRed = Color(red: 1.0, green: 0.15, blue: 0.15)
}

import AppKit
import WebKit

struct MenuBarView: View {
    @Bindable var store: SpotifyStore
    
    var body: some View {
        ZStack {
            GeometryReader { geo in
                if geo.size.width > 700 {
                    DesktopDashboardView(store: store)
                } else {
                    CompactPlayerView(store: store)
                }
            }
            .frame(minWidth: 320, idealWidth: 320, maxWidth: .infinity, minHeight: 450, idealHeight: 450, maxHeight: .infinity)
            
            if store.showFullScreenPlayer {
                FullScreenPlayerView(store: store)
                    .transition(.move(edge: .bottom))
                    .zIndex(100)
            }
        }
        .background(
            LinearGradient(
                colors: [Color(red: 0.08, green: 0.08, blue: 0.12), Color(red: 0.12, green: 0.11, blue: 0.18)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .colorScheme(.dark)
    }
}

struct CompactPlayerView: View {
    @Bindable var store: SpotifyStore
    
    var body: some View {
        VStack(spacing: 0) {
            if store.isMiniPlayerMode {
                MiniPlayerView(store: store)
            } else {
                // Header / Tab Selector
                HeaderView(store: store)
                
                Divider()
                    .background(Color.white.opacity(0.1))
                
                // Content Panel
                ZStack {
                    VStack(spacing: 0) {
                        switch store.selectedTab {
                        case "player":
                            NowPlayingView(store: store)
                        case "playlists":
                            PlaylistsView(store: store)
                        case "search":
                            SearchView(store: store)
                        case "equalizer":
                            if store.enableFeatureEqualizer {
                                EqualizerView(store: store)
                            } else {
                                NowPlayingView(store: store)
                            }
                        case "insights":
                            if store.enableFeatureVibeInsights {
                                AudioInsightsView(store: store)
                            } else {
                                NowPlayingView(store: store)
                            }
                        case "analytics":
                            AnalyticsView(store: store)
                        case "settings":
                            SettingsView(store: store)
                        default:
                            NowPlayingView(store: store)
                        }
                    }
                    .frame(maxWidth: 600)
                    .frame(maxWidth: .infinity)
                    
                    if let artistDetails = store.activeArtistDetails {
                        ArtistDetailView(store: store, artistDetails: artistDetails)
                            .background(
                                LinearGradient(
                                    colors: [Color(red: 0.08, green: 0.08, blue: 0.12), Color(red: 0.12, green: 0.11, blue: 0.18)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .transition(.move(edge: .trailing))
                            .zIndex(5)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                Divider()
                    .background(Color.white.opacity(0.1))
                
                // Performance / Stats Footer
                ResourceMonitorView(store: store)
            }
        }
    }
}

struct DesktopDashboardView: View {
    @Bindable var store: SpotifyStore
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                // Column 1: Left Sidebar
                VStack(alignment: .leading, spacing: 20) {
                    // Logo / Title
                    Text("Muzeebra")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.winampOrange, .winampRed],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                    
                    // Nav Group
                    VStack(alignment: .leading, spacing: 4) {
                        SidebarNavButton(icon: "music.note", title: "Now Playing", active: store.selectedTab == "player") {
                            store.selectedTab = "player"
                        }
                        SidebarNavButton(icon: "music.note.list", title: "Playlists", active: store.selectedTab == "playlists") {
                            store.selectedTab = "playlists"
                        }
                        SidebarNavButton(icon: "magnifyingglass", title: "Search", active: store.selectedTab == "search") {
                            store.selectedTab = "search"
                        }
                        if store.enableFeatureEqualizer {
                            SidebarNavButton(icon: "slider.horizontal.3", title: "Equalizer", active: store.selectedTab == "equalizer") {
                                store.selectedTab = "equalizer"
                            }
                        }
                        if store.enableFeatureVibeInsights {
                            SidebarNavButton(icon: "waveform.path.ecg", title: "Audio Vibe", active: store.selectedTab == "insights") {
                                store.selectedTab = "insights"
                            }
                        }
                        SidebarNavButton(icon: "chart.bar.fill", title: "Analytics", active: store.selectedTab == "analytics") {
                            store.selectedTab = "analytics"
                            if store.isOnlineLoggedIn {
                                store.fetchOnlineAnalytics()
                            }
                        }
                        SidebarNavButton(icon: "gearshape", title: "Settings", active: store.selectedTab == "settings") {
                            store.selectedTab = "settings"
                        }
                    }
                    
                    Spacer()
                }
                .frame(width: 150)
                .background(Color.black.opacity(0.2))
                
                Divider()
                    .background(Color.white.opacity(0.08))
                
                // Column 2: Center Content Area
                VStack(spacing: 0) {
                    if let artistDetails = store.activeArtistDetails {
                        ArtistDetailView(store: store, artistDetails: artistDetails)
                            .transition(.move(edge: .trailing))
                    } else {
                        ScrollView {
                            VStack(spacing: 16) {
                                switch store.selectedTab {
                                case "player":
                                    DesktopPlayerDashboardView(store: store)
                                case "playlists":
                                    PlaylistsView(store: store)
                                case "search":
                                    SearchView(store: store)
                                case "equalizer":
                                    if store.enableFeatureEqualizer {
                                        EqualizerView(store: store)
                                    } else {
                                        DesktopPlayerDashboardView(store: store)
                                    }
                                case "insights":
                                    if store.enableFeatureVibeInsights {
                                        AudioInsightsView(store: store)
                                    } else {
                                        DesktopPlayerDashboardView(store: store)
                                    }
                                case "analytics":
                                    AnalyticsView(store: store)
                                case "settings":
                                    SettingsView(store: store)
                                default:
                                    DesktopPlayerDashboardView(store: store)
                                }
                            }
                            .padding(20)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                Divider()
                    .background(Color.white.opacity(0.08))
                
                // Column 3: Right Sidebar (Queue)
                VStack(spacing: 0) {
                    DesktopQueueView(store: store)
                }
                .frame(width: 240)
                .background(Color.black.opacity(0.15))
            }
            
            Divider()
                .background(Color.white.opacity(0.08))
            
            // Bottom Playbar Controls
            DesktopPlaybarView(store: store)
                .frame(height: 72)
                .background(Color.black.opacity(0.3))
        }
    }
}

struct SidebarNavButton: View {
    let icon: String
    let title: String
    let active: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                // Active indicator line on the left side
                Rectangle()
                    .fill(active ? Color.winampOrange : Color.clear)
                    .frame(width: 3, height: 16)
                    
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(active ? .winampOrange : .gray)
                    .frame(width: 16)
                
                Text(title)
                    .font(.system(size: 12, weight: active ? .bold : .medium, design: .rounded))
                    .foregroundColor(active ? .white : .gray)
                
                Spacer()
            }
            .frame(height: 32)
            .background(active ? Color.white.opacity(0.05) : Color.clear)
        }
        .buttonStyle(.plain)
    }
}

struct DesktopPlayerDashboardView: View {
    var store: SpotifyStore
    @State private var hoverTrackUri: String? = nil
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 28) {
                // Featured Large Card (Now Playing Banner)
                NowPlayingBannerCard(store: store)
                
                if !store.isLocalMode && SpotifyWebService.shared.isLoggedIn {
                    // Recommended for You (Vertical List)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recommended for You")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        if store.recommendedTracks.isEmpty {
                            Text("Play more music to get personalized recommendations.")
                                .font(.system(size: 11))
                                .foregroundColor(.gray)
                                .padding(.vertical, 8)
                        } else {
                            VStack(spacing: 6) {
                                ForEach(store.recommendedTracks) { track in
                                    HStack(spacing: 12) {
                                        // Artwork
                                        if !track.artworkUrl.isEmpty, let url = URL(string: track.artworkUrl) {
                                            AsyncImage(url: url) { image in
                                                image.resizable()
                                                    .aspectRatio(contentMode: .fill)
                                            } placeholder: {
                                                Color.gray.opacity(0.2)
                                            }
                                            .frame(width: 40, height: 40)
                                            .cornerRadius(6)
                                        } else {
                                            ZStack {
                                                Color.gray.opacity(0.2)
                                                Image(systemName: "music.note")
                                                    .foregroundColor(.gray)
                                            }
                                            .frame(width: 40, height: 40)
                                            .cornerRadius(6)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(track.name)
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundColor(.white)
                                                .lineLimit(1)
                                            
                                            Text(track.artist)
                                                .font(.system(size: 10))
                                                .foregroundColor(.gray)
                                                .lineLimit(1)
                                        }
                                        
                                        Spacer()
                                        
                                        // Play / Context menu indicators
                                        if hoverTrackUri == track.uri {
                                            Button(action: {
                                                store.playTrack(uri: track.uri)
                                            }) {
                                                Image(systemName: "play.fill")
                                                    .font(.system(size: 11))
                                                    .foregroundColor(.winampOrange)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                        
                                        Menu {
                                            Button(action: {
                                                store.playTrack(uri: track.uri)
                                            }) {
                                                Label("Play Now", systemImage: "play.fill")
                                            }
                                            
                                            Button(action: {
                                                store.addToQueue(uri: track.uri)
                                            }) {
                                                Label("Add to Queue", systemImage: "text.insert")
                                            }
                                            
                                            if !store.playlists.isEmpty {
                                                Menu("Add to Playlist") {
                                                    ForEach(store.playlists) { playlist in
                                                        Button(playlist.name) {
                                                            store.addTrackToPlaylist(trackUri: track.uri, playlistId: playlist.id)
                                                        }
                                                    }
                                                }
                                            }
                                        } label: {
                                            Image(systemName: "ellipsis")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(.gray)
                                                .padding(6)
                                                .contentShape(Rectangle())
                                        }
                                        .menuStyle(.borderlessButton)
                                        .frame(width: 20)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(hoverTrackUri == track.uri ? Color.white.opacity(0.05) : Color.clear)
                                    )
                                    .onHover { isHovered in
                                        hoverTrackUri = isHovered ? track.uri : nil
                                    }
                                }
                            }
                        }
                    }
                    
                    // Featured Playlists (Horizontal Scroll)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Featured Playlists")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        if store.featuredPlaylists.isEmpty {
                            Text("Featured playlists are currently unavailable.")
                                .font(.system(size: 11))
                                .foregroundColor(.gray)
                                .padding(.vertical, 8)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(store.featuredPlaylists) { playlist in
                                        Button(action: {
                                            store.fetchPlaylistTracks(id: playlist.id, name: playlist.name, artworkUrl: playlist.artworkUrl)
                                            store.selectedTab = "playlists"
                                        }) {
                                            VStack(alignment: .leading, spacing: 8) {
                                                if !playlist.artworkUrl.isEmpty, let url = URL(string: playlist.artworkUrl) {
                                                    AsyncImage(url: url) { image in
                                                        image.resizable()
                                                            .aspectRatio(contentMode: .fill)
                                                    } placeholder: {
                                                        Color.gray.opacity(0.2)
                                                    }
                                                    .frame(width: 110, height: 110)
                                                    .cornerRadius(8)
                                                } else {
                                                    ZStack {
                                                        Color.gray.opacity(0.2)
                                                        Image(systemName: "music.note.list")
                                                            .font(.system(size: 30))
                                                            .foregroundColor(.gray)
                                                    }
                                                    .frame(width: 110, height: 110)
                                                    .cornerRadius(8)
                                                }
                                                
                                                Text(playlist.name)
                                                    .font(.system(size: 11, weight: .semibold))
                                                    .foregroundColor(.white)
                                                    .lineLimit(1)
                                                    .frame(width: 110, alignment: .leading)
                                                
                                                Text("\(playlist.trackCount) Songs")
                                                    .font(.system(size: 9))
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }
                    
                    // New Releases (Horizontal Scroll)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("New Releases")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        if store.newReleases.isEmpty {
                            Text("New releases are currently unavailable.")
                                .font(.system(size: 11))
                                .foregroundColor(.gray)
                                .padding(.vertical, 8)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(store.newReleases) { album in
                                        Button(action: {
                                            store.playContext(uri: album.uri)
                                        }) {
                                            VStack(alignment: .leading, spacing: 8) {
                                                if !album.artworkUrl.isEmpty, let url = URL(string: album.artworkUrl) {
                                                    AsyncImage(url: url) { image in
                                                        image.resizable()
                                                            .aspectRatio(contentMode: .fill)
                                                    } placeholder: {
                                                        Color.gray.opacity(0.2)
                                                    }
                                                    .frame(width: 110, height: 110)
                                                    .cornerRadius(8)
                                                } else {
                                                    ZStack {
                                                        Color.gray.opacity(0.2)
                                                        Image(systemName: "album")
                                                            .font(.system(size: 30))
                                                            .foregroundColor(.gray)
                                                    }
                                                    .frame(width: 110, height: 110)
                                                    .cornerRadius(8)
                                                }
                                                
                                                Text(album.name)
                                                    .font(.system(size: 11, weight: .semibold))
                                                    .foregroundColor(.white)
                                                    .lineLimit(1)
                                                    .frame(width: 110, alignment: .leading)
                                                
                                                Text(album.artist)
                                                    .font(.system(size: 9))
                                                    .foregroundColor(.gray)
                                                    .lineLimit(1)
                                                    .frame(width: 110, alignment: .leading)
                                            }
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }
                } else {
                    // Fallback to "Your Playlists" (Local/Logged out mode dashboard view)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your Playlists")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        if store.playlists.isEmpty {
                            Text(store.isLocalMode ? "Launch Spotify app to show local tracks." : "No playlists found. Go to Playlists tab to create one.")
                                .font(.system(size: 11))
                                .foregroundColor(.gray)
                                .padding(.vertical, 8)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(store.playlists.prefix(5)) { playlist in
                                        Button(action: {
                                            store.fetchPlaylistTracks(id: playlist.id, name: playlist.name, artworkUrl: playlist.artworkUrl)
                                            store.selectedTab = "playlists"
                                        }) {
                                            VStack(alignment: .leading, spacing: 8) {
                                                if !playlist.artworkUrl.isEmpty, let url = URL(string: playlist.artworkUrl) {
                                                    AsyncImage(url: url) { image in
                                                        image.resizable()
                                                            .aspectRatio(contentMode: .fill)
                                                    } placeholder: {
                                                        Color.gray.opacity(0.2)
                                                    }
                                                    .frame(width: 100, height: 100)
                                                    .cornerRadius(8)
                                                } else {
                                                    ZStack {
                                                        Color.gray.opacity(0.2)
                                                        Image(systemName: "music.note.list")
                                                            .font(.system(size: 30))
                                                            .foregroundColor(.gray)
                                                    }
                                                    .frame(width: 100, height: 100)
                                                    .cornerRadius(8)
                                                }
                                                
                                                Text(playlist.name)
                                                    .font(.system(size: 11, weight: .semibold))
                                                    .foregroundColor(.white)
                                                    .lineLimit(1)
                                                    .frame(width: 100, alignment: .leading)
                                                
                                                Text("\(playlist.trackCount) Songs")
                                                    .font(.system(size: 9))
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(.bottom, 24)
        }
    }
}

struct NowPlayingBannerCard: View {
    var store: SpotifyStore
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Backdrop Gradient
            LinearGradient(
                colors: [Color.winampOrange.opacity(0.15), Color.black.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .background(Color.white.opacity(0.02))
            
            HStack(spacing: 24) {
                // Large Artwork
                if !store.artworkUrl.isEmpty {
                    AsyncImage(url: URL(string: store.artworkUrl)) { image in
                        image.resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "music.note")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                    }
                    .frame(width: 110, height: 110)
                    .cornerRadius(12)
                    .shadow(color: store.isPlaying ? .winampOrange.opacity(0.3) : .black, radius: 10)
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.05))
                            .frame(width: 110, height: 110)
                        Image(systemName: "music.note")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("NOW STREAMING")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.winampOrange)
                        .tracking(2)
                    
                    Text(store.trackName)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    Text(store.artist)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                    
                    if !store.albumName.isEmpty {
                        Text(store.albumName)
                            .font(.system(size: 11))
                            .foregroundColor(.gray.opacity(0.7))
                            .lineLimit(1)
                    }
                }
                
                Spacer()
            }
            .padding(20)
        }
        .frame(height: 150)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}

struct DesktopQueueView: View {
    var store: SpotifyStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Play Queue")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 12)
            
            Divider()
                .background(Color.white.opacity(0.08))
            
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if store.queue.isEmpty {
                        VStack(spacing: 8) {
                            Text("Queue is empty")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.gray)
                                .padding(.top, 40)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    } else {
                        LazyVStack(spacing: 4) {
                            ForEach(Array(store.queue.prefix(15).enumerated()), id: \.offset) { index, track in
                                Button(action: {
                                    store.playTrack(uri: track.uri)
                                }) {
                                    HStack(spacing: 10) {
                                        Text("\(index + 1)")
                                            .font(.system(size: 9, design: .monospaced))
                                            .foregroundColor(.gray)
                                            .frame(width: 14, alignment: .leading)
                                        
                                        if !track.artworkUrl.isEmpty {
                                            AsyncImage(url: URL(string: track.artworkUrl)) { img in
                                                img.resizable()
                                                    .aspectRatio(contentMode: .fill)
                                            } placeholder: {
                                                Image(systemName: "music.note")
                                            }
                                            .frame(width: 28, height: 28)
                                            .background(Color.white.opacity(0.05))
                                            .cornerRadius(4)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text(track.name)
                                                .font(.system(size: 11, weight: .semibold))
                                                .foregroundColor(.white)
                                                .lineLimit(1)
                                            Text(track.artist)
                                                .font(.system(size: 9))
                                                .foregroundColor(.gray)
                                                .lineLimit(1)
                                        }
                                        Spacer()
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 4)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
}

struct DesktopPlaybarView: View {
    var store: SpotifyStore
    @State private var showDevicesPopup = false
    
    var body: some View {
        HStack(spacing: 20) {
            // Left: Current Track Details
            HStack(spacing: 12) {
                if !store.artworkUrl.isEmpty {
                    AsyncImage(url: URL(string: store.artworkUrl)) { image in
                        image.resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "music.note")
                    }
                    .frame(width: 44, height: 44)
                    .cornerRadius(6)
                } else {
                    ZStack {
                        Color.white.opacity(0.05)
                        Image(systemName: "music.note")
                    }
                    .frame(width: 44, height: 44)
                    .cornerRadius(6)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(store.trackName)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Text(store.artist)
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                .frame(width: 140, alignment: .leading)
            }
            .padding(.leading, 16)
            
            Spacer()
            
            // Center: Controls & Slider
            VStack(spacing: 6) {
                // Playback Buttons
                HStack(spacing: 16) {
                    Button(action: { store.toggleShuffle() }) {
                        Image(systemName: "shuffle")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(store.isLocalMode ? .gray.opacity(0.3) : (store.shuffleState ? .winampOrange : .gray))
                    }
                    .buttonStyle(.plain)
                    .disabled(store.isLocalMode)
                    
                    Button(action: { store.previousTrack() }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { store.playPause() }) {
                        ZStack {
                            Circle()
                                .fill(Color.winampOrange)
                                .frame(width: 32, height: 32)
                            Image(systemName: store.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 13))
                                .foregroundColor(.black)
                                .offset(x: store.isPlaying ? 0 : 1)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { store.nextTrack() }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                    }
                    .buttonStyle(.plain)
                }
                
                // Progress slider
                HStack(spacing: 8) {
                    let durationSec = Double(store.durationMs) / 1000.0
                    let currentSec = store.positionMs / 1000.0
                    let progress = durationSec > 0 ? currentSec / durationSec : 0.0
                    
                    Text(formatTime(currentSec))
                        .font(.system(size: 9))
                        .foregroundColor(.gray)
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 3)
                            Capsule()
                                .fill(Color.winampOrange)
                                .frame(width: geo.size.width * CGFloat(progress), height: 3)
                        }
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onEnded { value in
                                    let fraction = value.location.x / geo.size.width
                                    let boundedFraction = max(0.0, min(1.0, fraction))
                                    store.seek(to: boundedFraction)
                                }
                        )
                    }
                    .frame(height: 3)
                    .frame(width: 260)
                    
                    Text(formatTime(durationSec))
                        .font(.system(size: 9))
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Right: Volume & Devices
            HStack(spacing: 12) {
                Image(systemName: store.volume == 0 ? "speaker.slash.fill" : (store.volume < 40 ? "speaker.wave.1.fill" : "speaker.wave.3.fill"))
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
                
                Slider(value: Binding(
                    get: { Double(store.volume) },
                    set: { store.setVolume(to: Int($0)) }
                ), in: 0...100)
                .accentColor(.winampOrange)
                .controlSize(.small)
                .frame(width: 80)
                
                if !store.isLocalMode {
                    Button(action: {
                        store.fetchWebDevices()
                        showDevicesPopup.toggle()
                    }) {
                        Image(systemName: "ipad.and.iphone")
                            .font(.system(size: 12))
                            .foregroundColor(store.activeDeviceId.isEmpty ? .gray : .winampOrange)
                            .padding(4)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showDevicesPopup, arrowEdge: .top) {
                        DevicesPopoverView(store: store)
                    }
                }
                
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                        store.showFullScreenPlayer = true
                    }
                }) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .padding(4)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(4)
                }
                .buttonStyle(.plain)
            }
            .padding(.trailing, 16)
        }
    }
    
    private func formatTime(_ seconds: Double) -> String {
        guard !seconds.isNaN && !seconds.isInfinite && seconds > 0 else { return "0:00" }
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// Header
struct HeaderView: View {
    @Bindable var store: SpotifyStore
    
    var body: some View {
        HStack(spacing: 0) {
            Text("Muzeebra")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.winampOrange, .winampRed],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .padding(.leading, 16)
            
            Spacer()
            
            // Tab Selector
            HStack(spacing: 4) {
                TabButton(icon: "music.note", tabName: "player", selectedTab: $store.selectedTab)
                TabButton(icon: "music.note.list", tabName: "playlists", selectedTab: $store.selectedTab)
                TabButton(icon: "magnifyingglass", tabName: "search", selectedTab: $store.selectedTab)
                if store.enableFeatureEqualizer {
                    TabButton(icon: "slider.horizontal.3", tabName: "equalizer", selectedTab: $store.selectedTab)
                }
                if store.enableFeatureVibeInsights {
                    TabButton(icon: "waveform.path.ecg", tabName: "insights", selectedTab: $store.selectedTab)
                }
                TabButton(icon: "chart.bar.fill", tabName: "analytics", selectedTab: $store.selectedTab)
                TabButton(icon: "gearshape", tabName: "settings", selectedTab: $store.selectedTab)
            }
            .padding(.trailing, 12)
        }
        .frame(height: 48)
    }
}

struct TabButton: View {
    let icon: String
    let tabName: String
    @Binding var selectedTab: String
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tabName
            }
        }) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(selectedTab == tabName ? .winampOrange : .gray)
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(selectedTab == tabName ? Color.white.opacity(0.08) : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }
}

// Now Playing View
struct NowPlayingView: View {
    var store: SpotifyStore
    @State private var isHoveringArt = false
    @State private var showDevicesPopup = false
    @State private var showQueue = false
    
    var body: some View {
        VStack(spacing: 16) {
            if !store.isLocalMode && !SpotifyWebService.shared.isLoggedIn {
                Spacer()
                
                VStack(spacing: 16) {
                    Image(systemName: "safari.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.winampOrange)
                        .padding(.bottom, 2)
                    
                    Text("Connect Spotify Cloud")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Muzeebra uses secure client-side PKCE authentication. Please enter your Client ID below to connect.")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .lineSpacing(3)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Spotify Client ID:")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.gray)
                        
                        TextField("Enter Client ID...", text: Binding(
                            get: { SpotifyWebService.shared.clientId },
                            set: { SpotifyWebService.shared.clientId = $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 11))
                        .frame(width: 220)
                    }
                    .padding(.vertical, 4)
                    
                    Button(action: {
                        let cid = SpotifyWebService.shared.clientId.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !cid.isEmpty else { return }
                        
                        SpotifyWebService.shared.initiateLogin(clientId: cid) { result in
                            DispatchQueue.main.async {
                                if case .success = result {
                                    store.refreshState()
                                }
                            }
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "key.fill")
                                .font(.system(size: 11))
                            Text("Login to Spotify")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .frame(width: 220)
                        .padding(.vertical, 8)
                        .background(SpotifyWebService.shared.clientId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray.opacity(0.2) : Color.winampOrange)
                        .foregroundColor(SpotifyWebService.shared.clientId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .black)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .disabled(SpotifyWebService.shared.clientId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(16)
                .background(Color.white.opacity(0.02))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.04), lineWidth: 1)
                )
                .padding(.horizontal, 16)
                
                Spacer()
            } else {
                ZStack {
                    if showQueue {
                        QueuePanelView(store: store, isPresented: $showQueue)
                            .transition(.move(edge: .trailing))
                    } else {
                        VStack(spacing: 16) {
                            // Album artwork / Track Meta
                            HStack(spacing: 14) {
                                // Artwork
                                ZStack {
                                    if !store.artworkUrl.isEmpty {
                                        AsyncImage(url: URL(string: store.artworkUrl)) { image in
                                            image.resizable()
                                                .aspectRatio(contentMode: .fill)
                                        } placeholder: {
                                            Image(systemName: "music.note")
                                                .font(.system(size: 30))
                                                .foregroundColor(.gray.opacity(0.5))
                                        }
                                    } else {
                                        Image(systemName: "music.note")
                                            .font(.system(size: 30))
                                            .foregroundColor(.gray.opacity(0.5))
                                    }
                                }
                                .frame(width: 80, height: 80)
                                .background(Color.white.opacity(0.03))
                                .cornerRadius(12)
                                .shadow(color: store.isPlaying ? .winampOrange.opacity(0.2) : .black.opacity(0.3), radius: 10, x: 0, y: 5)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                )
                                
                                // Meta info
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(store.trackName)
                                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                                .lineLimit(1)
                                                .foregroundColor(.white)
                                            
                                            Text(store.artist)
                                                .font(.system(size: 13, weight: .medium))
                                                .lineLimit(1)
                                                .foregroundColor(.gray)
                                        }
                                        
                                        Spacer()
                                        
                                        // Equalizer
                                        if !store.lowPowerMode {
                                            EqualizerVisualizer(isPlaying: store.isPlaying)
                                        }
                                    }
                                    
                                    if !store.albumName.isEmpty {
                                        Text(store.albumName)
                                            .font(.system(size: 11))
                                            .lineLimit(1)
                                            .foregroundColor(.gray.opacity(0.7))
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                            
                            // Progress Bar
                            VStack(spacing: 4) {
                                let durationSec = Double(store.durationMs) / 1000.0
                                let currentSec = store.positionMs / 1000.0
                                let progress = durationSec > 0 ? currentSec / durationSec : 0.0
                                
                                // Custom Slider
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        // Background
                                        Capsule()
                                            .fill(Color.white.opacity(0.1))
                                            .frame(height: 4)
                                        
                                        // Fill
                                        Capsule()
                                            .fill(Color.winampOrange)
                                            .frame(width: geo.size.width * CGFloat(progress), height: 4)
                                    }
                                    .gesture(
                                        DragGesture(minimumDistance: 0)
                                            .onEnded { value in
                                                let fraction = value.location.x / geo.size.width
                                                let boundedFraction = max(0.0, min(1.0, fraction))
                                                store.seek(to: boundedFraction)
                                            }
                                    )
                                }
                                .frame(height: 6)
                                
                                HStack {
                                    Text(formatTime(currentSec))
                                        .font(.system(size: 10))
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Text(formatTime(durationSec))
                                        .font(.system(size: 10))
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.horizontal, 16)
                            
                            // Playback Controls
                            HStack(spacing: 24) {
                                Button(action: {
                                    store.toggleShuffle()
                                }) {
                                    Image(systemName: "shuffle")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(store.isLocalMode ? .gray.opacity(0.3) : (store.shuffleState ? .winampOrange : .gray))
                                }
                                .buttonStyle(.plain)
                                .disabled(store.isLocalMode)
                                
                                Button(action: {
                                    store.previousTrack()
                                }) {
                                    Image(systemName: "backward.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(.white)
                                }
                                .buttonStyle(.plain)
                                
                                Button(action: {
                                    store.playPause()
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.winampOrange)
                                            .frame(width: 48, height: 48)
                                            .shadow(color: .winampOrange.opacity(0.4), radius: 8)
                                        
                                        Image(systemName: store.isPlaying ? "pause.fill" : "play.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(.black)
                                            .offset(x: store.isPlaying ? 0 : 2)
                                    }
                                }
                                .buttonStyle(.plain)
                                
                                Button(action: {
                                    store.nextTrack()
                                }) {
                                    Image(systemName: "forward.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(.white)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.top, 8)
                            
                            // Volume / Devices Footer
                            HStack(spacing: 12) {
                                Image(systemName: store.volume == 0 ? "speaker.slash.fill" : (store.volume < 40 ? "speaker.wave.1.fill" : "speaker.wave.3.fill"))
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                                
                                Slider(value: Binding(
                                    get: { Double(store.volume) },
                                    set: { store.setVolume(to: Int($0)) }
                                ), in: 0...100)
                                .accentColor(.winampOrange)
                                .controlSize(.small)
                                
                                // Device Selector Button
                                if !store.isLocalMode {
                                    Button(action: {
                                        store.fetchWebDevices()
                                        showDevicesPopup.toggle()
                                    }) {
                                        Image(systemName: "ipad.and.iphone")
                                            .font(.system(size: 13))
                                            .foregroundColor(store.activeDeviceId.isEmpty ? .gray : .winampOrange)
                                            .padding(6)
                                            .background(Color.white.opacity(0.05))
                                            .cornerRadius(6)
                                    }
                                    .buttonStyle(.plain)
                                    .popover(isPresented: $showDevicesPopup, arrowEdge: .top) {
                                        DevicesPopoverView(store: store)
                                    }
                                    
                                    Button(action: {
                                        store.fetchQueue()
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            showQueue = true
                                        }
                                    }) {
                                        Image(systemName: "list.bullet")
                                            .font(.system(size: 13))
                                            .foregroundColor(showQueue ? .winampOrange : .gray)
                                            .padding(6)
                                            .background(Color.white.opacity(0.05))
                                            .cornerRadius(6)
                                    }
                                    .buttonStyle(.plain)
                                    
                                    Button(action: {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                            store.showFullScreenPlayer = true
                                        }
                                    }) {
                                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                                            .font(.system(size: 13))
                                            .foregroundColor(.gray)
                                            .padding(6)
                                            .background(Color.white.opacity(0.05))
                                            .cornerRadius(6)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 16)
                            
                            Spacer()
                        }
                        .transition(.move(edge: .leading))
                    }
                }
            }
        }
    }
    
    private func formatTime(_ seconds: Double) -> String {
        guard !seconds.isNaN && !seconds.isInfinite && seconds > 0 else { return "0:00" }
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// Queue Panel View
struct QueuePanelView: View {
    var store: SpotifyStore
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isPresented = false
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .bold))
                        Text("Back")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.winampOrange)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Text("Play Queue")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("Back")
                    .font(.system(size: 12))
                    .foregroundColor(.clear)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    // Now Playing Section
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Now Playing")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.gray)
                            .padding(.horizontal, 16)
                        
                        HStack(spacing: 10) {
                            if !store.artworkUrl.isEmpty {
                                AsyncImage(url: URL(string: store.artworkUrl)) { img in
                                    img.resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Image(systemName: "music.note")
                                }
                                .frame(width: 36, height: 36)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(6)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(store.trackName)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.winampOrange)
                                    .lineLimit(1)
                                
                                Text(store.artist)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.gray)
                                    .lineLimit(1)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.winampOrange.opacity(0.05))
                    }
                    .padding(.top, 8)
                    
                    // Next Up Section
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Next Up")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.gray)
                            .padding(.horizontal, 16)
                        
                        if store.queue.isEmpty {
                            Text("Queue is empty")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.gray)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                        } else {
                            LazyVStack(spacing: 4) {
                                ForEach(Array(store.queue.enumerated()), id: \.offset) { index, track in
                                    HStack(spacing: 10) {
                                        Text("\(index + 1)")
                                            .font(.system(size: 9, design: .monospaced))
                                            .foregroundColor(.gray)
                                            .frame(width: 14, alignment: .leading)
                                        
                                        if !track.artworkUrl.isEmpty {
                                            AsyncImage(url: URL(string: track.artworkUrl)) { img in
                                                img.resizable()
                                                    .aspectRatio(contentMode: .fill)
                                            } placeholder: {
                                                Image(systemName: "music.note")
                                            }
                                            .frame(width: 28, height: 28)
                                            .background(Color.white.opacity(0.05))
                                            .cornerRadius(4)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text(track.name)
                                                .font(.system(size: 11, weight: .semibold))
                                                .foregroundColor(.white)
                                                .lineLimit(1)
                                            Text(track.artist)
                                                .font(.system(size: 9))
                                                .foregroundColor(.gray)
                                                .lineLimit(1)
                                        }
                                        Spacer()
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [Color(red: 0.08, green: 0.08, blue: 0.12), Color(red: 0.12, green: 0.11, blue: 0.18)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}


// Devices Popover View
struct DevicesPopoverView: View {
    var store: SpotifyStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Connect to a device")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.top, 8)
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            if store.devices.isEmpty {
                Text("No devices found")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
                    .padding(12)
            } else {
                ScrollView {
                    VStack(spacing: 4) {
                        ForEach(store.devices) { dev in
                            Button(action: {
                                store.transferPlayback(to: dev.id)
                            }) {
                                HStack {
                                    Image(systemName: dev.type == "Computer" ? "desktopcomputer" : "iphone")
                                        .font(.system(size: 11))
                                        .foregroundColor(dev.isActive ? .winampOrange : .white)
                                    
                                    Text(dev.name)
                                        .font(.system(size: 11, weight: dev.isActive ? .bold : .regular))
                                        .foregroundColor(dev.isActive ? .winampOrange : .white)
                                    
                                    Spacer()
                                    
                                    if dev.isActive {
                                        Circle()
                                            .fill(Color.winampOrange)
                                            .frame(width: 6, height: 6)
                                    }
                                }
                                .padding(.vertical, 6)
                                .padding(.horizontal, 10)
                                .background(Color.white.opacity(dev.isActive ? 0.05 : 0.0))
                                .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 6)
                }
                .frame(maxHeight: 180)
            }
        }
        .frame(width: 200)
        .background(Color(red: 0.1, green: 0.1, blue: 0.15))
    }
}

// Equalizer Animated visualizer
struct EqualizerVisualizer: View {
    let isPlaying: Bool
    @State private var heights: [CGFloat] = [10, 15, 8, 20, 12, 17]
    let timer = Timer.publish(every: 0.15, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(0..<heights.count, id: \.self) { i in
                RoundedRectangle(cornerRadius: 1)
                    .fill(LinearGradient(colors: [.winampOrange, .winampRed], startPoint: .top, endPoint: .bottom))
                    .frame(width: 2, height: isPlaying ? heights[i] : 3)
            }
        }
        .frame(height: 20)
        .onReceive(timer) { _ in
            guard isPlaying else { return }
            withAnimation(.easeInOut(duration: 0.15)) {
                for i in 0..<heights.count {
                    heights[i] = CGFloat.random(in: 3...20)
                }
            }
        }
    }
}

// Search View
struct SearchView: View {
    @Bindable var store: SpotifyStore
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Input
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                    .font(.system(size: 13))
                
                TextField("Search tracks...", text: $store.searchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .disabled(store.isLocalMode)
                
                if !store.searchQuery.isEmpty {
                    Button(action: { store.searchQuery = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color.white.opacity(0.05))
            .cornerRadius(8)
            .padding(.horizontal, 16)
            .padding(.top, 12)
            
            if store.isLocalMode {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "lock.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.gray.opacity(0.5))
                    Text("Search is cloud-only")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                    Text("Switch to Spotify Web API Mode in Settings to search and browse catalogs.")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                    Spacer()
                }
            } else if store.searchQuery.isEmpty {
                VStack {
                    Spacer()
                    Text("Search Spotify Catalog")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.gray)
                    Spacer()
                }
            } else if store.searchResults.isEmpty {
                VStack {
                    Spacer()
                    ProgressView()
                        .controlSize(.small)
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(store.searchResults) { track in
                            HStack(spacing: 6) {
                                Button(action: {
                                    store.playTrack(uri: track.uri)
                                }) {
                                    HStack(spacing: 10) {
                                        // Track Art
                                        ZStack {
                                            if !track.artworkUrl.isEmpty {
                                                AsyncImage(url: URL(string: track.artworkUrl)) { img in
                                                    img.resizable()
                                                        .aspectRatio(contentMode: .fill)
                                                } placeholder: {
                                                    Image(systemName: "music.note")
                                                        .foregroundColor(.gray)
                                                }
                                            } else {
                                                Image(systemName: "music.note")
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                        .frame(width: 32, height: 32)
                                        .background(Color.white.opacity(0.05))
                                        .cornerRadius(6)
                                        
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text(track.name)
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(.white)
                                                .lineLimit(1)
                                            Text(track.artist)
                                                .font(.system(size: 10))
                                                .foregroundColor(.gray)
                                                .lineLimit(1)
                                        }
                                        
                                        Spacer()
                                        
                                        Text(formatDuration(track.durationMs))
                                            .font(.system(size: 10))
                                            .foregroundColor(.gray.opacity(0.6))
                                    }
                                    .padding(6)
                                    .background(Color.white.opacity(0.03))
                                    .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                                
                                Menu {
                                    Button(action: {
                                        store.addToQueue(uri: track.uri)
                                    }) {
                                        Label("Add to Queue", systemImage: "text.insert.button")
                                    }
                                    
                                    Menu("Add to Playlist") {
                                        if store.playlists.isEmpty {
                                            Text("No Playlists Found")
                                        } else {
                                            ForEach(store.playlists) { playlist in
                                                Button(action: {
                                                    store.addTrackToPlaylist(trackUri: track.uri, playlistId: playlist.id)
                                                }) {
                                                    Text(playlist.name)
                                                }
                                            }
                                        }
                                    }
                                } label: {
                                    Image(systemName: "ellipsis")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.gray)
                                        .frame(width: 28, height: 28)
                                        .background(Color.white.opacity(0.05))
                                        .cornerRadius(6)
                                }
                                .menuStyle(.borderlessButton)
                                .frame(width: 28, height: 28)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
            }
        }
    }
    
    private func formatDuration(_ ms: Int) -> String {
        let seconds = ms / 1000
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// Settings View
struct SettingsView: View {
    @Bindable var store: SpotifyStore
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ConnectionSettingsView(store: store)
                OnlineSyncSettingsView(store: store)
                if store.enableFeatureSleepTimer || store.enableFeatureMiniPlayer {
                    UtilitySettingsView(store: store)
                }
                FeatureToggleSettingsView(store: store)
                CustomizationSettingsView(store: store)
                PerformanceSettingsView(store: store)
            }
            .padding(16)
        }
    }
}

// MARK: - Feature Toggle Settings View
struct FeatureToggleSettingsView: View {
    @Bindable var store: SpotifyStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "cpu")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.winampOrange)
                Text("Features & Resource Toggles")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Turn off extra features to disable their UI tabs, background timers, and API polling, keeping resource usage extremely low.")
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
                    .lineSpacing(3)
                    .padding(.bottom, 4)
                
                Toggle(isOn: $store.enableFeatureEqualizer) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Graphic Equalizer UI")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                        Text("Adds a tab for a classic 10-band Winamp-style equalizer interface.")
                            .font(.system(size: 9))
                            .foregroundColor(.gray)
                    }
                }
                .toggleStyle(.switch)
                .controlSize(.small)
                
                Divider().background(Color.white.opacity(0.05))
                
                Toggle(isOn: $store.enableFeatureVibeInsights) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Audio Vibe Insights")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                        Text("Queries Spotify's audio analysis API for beats, energy, valence, and tempo.")
                            .font(.system(size: 9))
                            .foregroundColor(.gray)
                    }
                }
                .toggleStyle(.switch)
                .controlSize(.small)
                
                Divider().background(Color.white.opacity(0.05))
                
                Toggle(isOn: $store.enableFeatureSleepTimer) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Sleep Timer")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                        Text("Enables countdown timers in settings to automatically pause music.")
                            .font(.system(size: 9))
                            .foregroundColor(.gray)
                    }
                }
                .toggleStyle(.switch)
                .controlSize(.small)
                
                Divider().background(Color.white.opacity(0.05))
                
                Toggle(isOn: $store.enableFeatureMiniPlayer) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Picture-in-Picture Mini Player")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                        Text("Enables floating always-on-top micro-controller view.")
                            .font(.system(size: 9))
                            .foregroundColor(.gray)
                    }
                }
                .toggleStyle(.switch)
                .controlSize(.small)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.02))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            )
        }
    }
}

// MARK: - Utility Settings View
struct UtilitySettingsView: View {
    @Bindable var store: SpotifyStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.winampOrange)
                Text("Utilities")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 12) {
                if store.enableFeatureSleepTimer {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Sleep Timer")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white)
                            if store.isSleepTimerActive {
                                Text("Playback will pause in \(formatTime(store.sleepTimerSecondsRemaining))")
                                    .font(.system(size: 9))
                                    .foregroundColor(.winampOrange)
                            } else {
                                Text("Automatically pause playback after a set duration.")
                                    .font(.system(size: 9))
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        Spacer()
                        
                        Picker("", selection: Binding<Int>(
                            get: { store.sleepTimerSelectedMinutes },
                            set: { value in
                                if value == 0 {
                                    store.stopSleepTimer()
                                } else {
                                    store.startSleepTimer(minutes: value)
                                }
                            }
                        )) {
                            Text("Off").tag(0)
                            Text("5 Min").tag(5)
                            Text("15 Min").tag(15)
                            Text("30 Min").tag(30)
                            Text("60 Min").tag(60)
                        }
                        .pickerStyle(.menu)
                        .frame(width: 90)
                    }
                }
                
                if store.enableFeatureSleepTimer && store.enableFeatureMiniPlayer {
                    Divider().background(Color.white.opacity(0.05))
                }
                
                if store.enableFeatureMiniPlayer {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Picture-in-Picture Mini Player")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white)
                            Text("Shrink the window to a small floating overlay on top of all windows.")
                                .font(.system(size: 9))
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Button(action: { store.toggleMiniPlayer() }) {
                            Text(store.isMiniPlayerMode ? "Exit Mini" : "Enter Mini")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.winampOrange)
                                .cornerRadius(4)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.02))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            )
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - Connection Settings View
struct ConnectionSettingsView: View {
    @Bindable var store: SpotifyStore
    @State private var clientIdField: String = ""
    @State private var loginMessage: String = ""
    @State private var isLoading = false
    @State private var showAdvanced = false
    
    var body: some View {
        let isLocalModeBinding = Binding<Bool>(
            get: { store.isLocalMode },
            set: { store.isLocalMode = $0 }
        )
        
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "link")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.winampOrange)
                Text("Connection & Account")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Picker("Mode", selection: isLocalModeBinding) {
                Text("Local App (AppleScript)").tag(true)
                Text("Cloud (Spotify Web API)").tag(false)
            }
            .pickerStyle(.segmented)
            
            if store.isLocalMode {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Zero-Auth Local Controller")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.winampOrange)
                    Text("Controls the official Spotify desktop application running on this Mac directly using AppleScript. Requires no Spotify login, no Client ID, and works offline.")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                        .lineSpacing(3)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.02))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
            } else {
                VStack(spacing: 10) {
                    if SpotifyWebService.shared.isLoggedIn {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.green)
                            Text("Connected to Spotify")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white)
                            Spacer()
                            Button("Logout") {
                                SpotifyWebService.shared.logout()
                                store.refreshState()
                                loginMessage = "Logged out successfully"
                            }
                            .controlSize(.small)
                        }
                    } else {
                        Button(action: {
                            isLoading = true
                            loginMessage = "Check your web browser..."
                            let targetCid = clientIdField.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty 
                                ? SpotifyWebService.defaultClientId 
                                : clientIdField.trimmingCharacters(in: .whitespacesAndNewlines)
                            
                            SpotifyWebService.shared.initiateLogin(clientId: targetCid) { result in
                                DispatchQueue.main.async {
                                    isLoading = false
                                    switch result {
                                    case .success:
                                        store.refreshState()
                                        loginMessage = "Linked successfully!"
                                    case .failure(let err):
                                        loginMessage = "Error: \(err.localizedDescription)"
                                    }
                                }
                            }
                        }) {
                            HStack {
                                if isLoading {
                                    ProgressView().controlSize(.small).padding(.trailing, 4)
                                }
                                Text("Link Spotify Account")
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.winampOrange)
                            .foregroundColor(.black)
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    if !loginMessage.isEmpty {
                        Text(loginMessage)
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    // Developer Options Switcher
                    Button(action: {
                        withAnimation {
                            showAdvanced.toggle()
                        }
                    }) {
                        HStack {
                            Text(showAdvanced ? "Hide Developer Options" : "Show Developer Options")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(.gray)
                            Spacer()
                            Image(systemName: showAdvanced ? "chevron.up" : "chevron.down")
                                .font(.system(size: 8))
                                .foregroundColor(.gray)
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                    
                    if showAdvanced {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Custom Spotify Client ID:")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.gray)
                            
                            TextField("Optional Client ID Override", text: $clientIdField)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(size: 10))
                            
                            Text("Leave empty to use Muzeebra's built-in default client ID.")
                                .font(.system(size: 8))
                                .foregroundColor(.gray.opacity(0.8))
                        }
                        .padding(.top, 2)
                        .transition(.opacity)
                    }
                }
                .padding(10)
                .background(Color.white.opacity(0.02))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
                .onAppear {
                    clientIdField = SpotifyWebService.shared.clientId == SpotifyWebService.defaultClientId ? "" : SpotifyWebService.shared.clientId
                }
            }
        }
        .padding(12)
        .background(Color.black.opacity(0.12))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}

// MARK: - Customization Settings View
struct CustomizationSettingsView: View {
    @Bindable var store: SpotifyStore
    
    var body: some View {
        let vinylBinding = Binding<Bool>(
            get: { store.enableVinylRotation },
            set: { store.enableVinylRotation = $0 }
        )
        let glowBinding = Binding<Bool>(
            get: { store.enableAmbientGlow },
            set: { store.enableAmbientGlow = $0 }
        )
        let lyricsBinding = Binding<Bool>(
            get: { store.enableLyricsSync },
            set: { store.enableLyricsSync = $0 }
        )
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "paintbrush")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.winampOrange)
                Text("Player Customization")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 12) {
                Toggle(isOn: vinylBinding) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Spinning Vinyl Record")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                        Text("Rotate the album artwork as a vinyl disc in full screen player.")
                            .font(.system(size: 9))
                            .foregroundColor(.gray)
                    }
                }
                .toggleStyle(.switch)
                .controlSize(.small)
                
                Divider().background(Color.white.opacity(0.05))
                
                Toggle(isOn: glowBinding) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Ambient Glow Backdrop")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                        Text("Dynamic, high-blur backdrop glow sourced from the album sleeve colors.")
                            .font(.system(size: 9))
                            .foregroundColor(.gray)
                    }
                }
                .toggleStyle(.switch)
                .controlSize(.small)
                
                Divider().background(Color.white.opacity(0.05))
                
                Toggle(isOn: lyricsBinding) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Auto-Scrolling Synced Lyrics")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                        Text("Keep the lyrics highlighted and scrolled to center with playback time.")
                            .font(.system(size: 9))
                            .foregroundColor(.gray)
                    }
                }
                .toggleStyle(.switch)
                .controlSize(.small)
            }
            .padding(10)
            .background(Color.white.opacity(0.02))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            )
        }
        .padding(12)
        .background(Color.black.opacity(0.12))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}

// MARK: - Performance Settings View
struct StatsRowView: View {
    let ram: String
    let cpu: String
    let api: String
    
    var body: some View {
        HStack(spacing: 4) {
            VStack(alignment: .leading, spacing: 2) {
                Text("RAM USAGE")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.gray)
                Text(ram)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
            }
            Spacer()
            VStack(alignment: .leading, spacing: 2) {
                Text("CPU LOAD")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.gray)
                Text(cpu)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
            }
            Spacer()
            VStack(alignment: .leading, spacing: 2) {
                Text("API COUNTER")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.gray)
                Text(api)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
            }
        }
    }
}

struct PerformanceSettingsView: View {
    @Bindable var store: SpotifyStore
    
    var body: some View {
        let lowPowerBinding = Binding<Bool>(
            get: { store.lowPowerMode },
            set: { store.lowPowerMode = $0 }
        )
        
        let ramString = formatMemory(store.memoryUsage)
        let cpuString = String(format: "%.1f %%", store.cpuUsage)
        let apiString = String(store.apiCallCount)
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "cpu")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.winampOrange)
                Text("Performance & Battery")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 12) {
                Toggle(isOn: lowPowerBinding) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Low Power Mode")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                        Text("Slows down polling update frequency to extend battery life.")
                            .font(.system(size: 9))
                            .foregroundColor(.gray)
                    }
                }
                .toggleStyle(.switch)
                .controlSize(.small)
                
                Divider().background(Color.white.opacity(0.05))
                
                StatsRowView(ram: ramString, cpu: cpuString, api: apiString)
                    .padding(.top, 4)
            }
            .padding(10)
            .background(Color.white.opacity(0.02))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            )
        }
        .padding(12)
        .background(Color.black.opacity(0.12))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
    
    private func formatMemory(_ bytes: UInt64) -> String {
        let megabytes = Double(bytes) / 1024.0 / 1024.0
        return String(format: "%.1f MB", megabytes)
    }
}

// Performance Monitor view
struct ResourceMonitorView: View {
    var store: SpotifyStore
    @State private var isCollapsed = true
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isCollapsed.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "cpu")
                        .font(.system(size: 10))
                        .foregroundColor(.winampOrange)
                    
                    Text("RAM: \(formatMemory(store.memoryUsage))")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Image(systemName: isCollapsed ? "chevron.up" : "chevron.down")
                        .font(.system(size: 9))
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 16)
                .frame(height: 28)
                .background(Color.white.opacity(0.02))
            }
            .buttonStyle(.plain)
            
            if !isCollapsed {
                VStack(spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("CPU LOAD (EST)")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.gray)
                            Text(String(format: "%.2f %%", store.cpuUsage))
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("API REQUESTS")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.gray)
                            Text("\(store.apiCallCount)")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.white)
                        }
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.05))
                    
                    // Low Power Mode Toggle
                    Toggle(isOn: Binding(
                        get: { store.lowPowerMode },
                        set: { store.lowPowerMode = $0 }
                    )) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Low Power Mode")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white)
                            Text("Slows update rates & stops visuals")
                                .font(.system(size: 9))
                                .foregroundColor(.gray)
                        }
                    }
                    .toggleStyle(.switch)
                    .controlSize(.small)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.black.opacity(0.15))
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
    
    private func formatMemory(_ bytes: UInt64) -> String {
        let megabytes = Double(bytes) / 1024.0 / 1024.0
        return String(format: "%.1f MB", megabytes)
    }
}

// User Playlists View Panel
struct PlaylistDetailView: View {
    var store: SpotifyStore
    let playlistDetails: SpotifyPlaylistDetails
    @State private var showDeleteConfirm = false
    @State private var hoverTrackUri: String? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with Back Button
            HStack {
                Button(action: {
                    store.activePlaylistDetails = nil
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .bold))
                        Text("Playlists")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.winampOrange)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                if showDeleteConfirm {
                    HStack(spacing: 8) {
                        Button(action: {
                            store.deletePlaylist(id: playlistDetails.id)
                            showDeleteConfirm = false
                        }) {
                            Text("Delete?")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: {
                            showDeleteConfirm = false
                        }) {
                            Text("Cancel")
                                .font(.system(size: 11))
                                .foregroundColor(.gray)
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    Button(action: {
                        showDeleteConfirm = true
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundColor(.red.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)
            
            // Playlist Banner
            HStack(spacing: 12) {
                if !playlistDetails.artworkUrl.isEmpty, let url = URL(string: playlistDetails.artworkUrl) {
                    AsyncImage(url: url) { image in
                        image.resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.gray.opacity(0.2)
                    }
                    .frame(width: 50, height: 50)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                } else {
                    ZStack {
                        Color.gray.opacity(0.2)
                        Image(systemName: "music.note.list")
                            .font(.system(size: 20))
                            .foregroundColor(.gray)
                    }
                    .frame(width: 50, height: 50)
                    .cornerRadius(8)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(playlistDetails.name)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text("\(playlistDetails.tracks.count) songs")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Play Playlist Button
                Button(action: {
                    store.playContext(uri: "spotify:playlist:\(playlistDetails.id)")
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.winampOrange)
                            .frame(width: 32, height: 32)
                        Image(systemName: "play.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.black)
                            .offset(x: 1)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // Tracks ScrollView
            ScrollView {
                if playlistDetails.tracks.isEmpty {
                    VStack(spacing: 8) {
                        Text("No songs in this playlist")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.gray)
                            .padding(.top, 40)
                    }
                } else {
                    LazyVStack(spacing: 4) {
                        ForEach(Array(playlistDetails.tracks.enumerated()), id: \.offset) { index, track in
                            Button(action: {
                                store.playTrack(uri: track.uri)
                            }) {
                                HStack(spacing: 8) {
                                    Text("\(index + 1)")
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundColor(.gray)
                                        .frame(width: 16, alignment: .leading)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(track.name)
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(.white)
                                            .lineLimit(1)
                                        Text(track.artist)
                                            .font(.system(size: 9))
                                            .foregroundColor(.gray)
                                            .lineLimit(1)
                                    }
                                    
                                    Spacer()
                                    
                                    if hoverTrackUri == track.uri {
                                        Image(systemName: "play.fill")
                                            .font(.system(size: 10))
                                            .foregroundColor(.winampOrange)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(hoverTrackUri == track.uri ? Color.white.opacity(0.05) : Color.clear)
                                )
                            }
                            .buttonStyle(.plain)
                            .onHover { isHovered in
                                hoverTrackUri = isHovered ? track.uri : nil
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct PlaylistsView: View {
    var store: SpotifyStore
    @State private var hoverPlaylistId: String? = nil
    @State private var showCreateField = false
    @State private var newPlaylistName = ""
    @State private var playlistTab: String = "myPlaylists" // "myPlaylists" or "discover"
    @State private var hoverTrackUri: String? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            if store.isLocalMode || !SpotifyWebService.shared.isLoggedIn {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 40))
                        .foregroundColor(.winampOrange)
                    Text("Playlists require Web Mode")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    Text("Switch to Cloud mode and link your Spotify account in Settings to view and play your personal playlists.")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                Spacer()
            } else if let activeDetails = store.activePlaylistDetails {
                PlaylistDetailView(store: store, playlistDetails: activeDetails)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            } else {
                VStack(spacing: 0) {
                    // Segmented Controller for switching tabs
                    Picker("", selection: $playlistTab) {
                        Text("My Playlists").tag("myPlaylists")
                        Text("Discover").tag("discover")
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                    
                    if playlistTab == "myPlaylists" {
                        // Playlist Header with "+" Creation Trigger
                        HStack {
                            Text("Your Playlists")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Button(action: {
                                store.openLocalPlaylistPicker()
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "folder")
                                        .font(.system(size: 11))
                                    Text("Open Local")
                                        .font(.system(size: 10, weight: .bold))
                                }
                                .foregroundColor(.winampOrange)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.06))
                                .cornerRadius(4)
                            }
                            .buttonStyle(.plain)
                            .padding(.trailing, 8)
                            
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    showCreateField.toggle()
                                }
                            }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.winampOrange)
                            }
                            .buttonStyle(.plain)
                            .padding(.trailing, 8)
                            
                            Button(action: {
                                store.fetchWebPlaylists()
                            }) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.gray)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                        
                        // Inline Create Playlist Field
                        if showCreateField {
                            HStack(spacing: 8) {
                                TextField("New playlist name...", text: $newPlaylistName, onCommit: {
                                    handleCreatePlaylist()
                                })
                                .textFieldStyle(.roundedBorder)
                                .font(.system(size: 11))
                                
                                Button(action: {
                                    handleCreatePlaylist()
                                }) {
                                    Text("Create")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.winampOrange)
                                        .cornerRadius(4)
                                }
                                .buttonStyle(.plain)
                                .disabled(newPlaylistName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 10)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                if store.playlists.isEmpty {
                                    VStack(spacing: 8) {
                                        Text("No playlists found")
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(.gray)
                                            .padding(.top, 40)
                                    }
                                } else {
                                    ForEach(store.playlists) { playlist in
                                        HStack(spacing: 12) {
                                            // Playlist Art
                                            if !playlist.artworkUrl.isEmpty, let url = URL(string: playlist.artworkUrl) {
                                                AsyncImage(url: url) { image in
                                                    image.resizable()
                                                } placeholder: {
                                                    Color.gray.opacity(0.2)
                                                }
                                                .frame(width: 42, height: 42)
                                                .cornerRadius(6)
                                            } else {
                                                ZStack {
                                                    Color.gray.opacity(0.2)
                                                    Image(systemName: "music.note.list")
                                                        .font(.system(size: 16))
                                                        .foregroundColor(.gray)
                                                }
                                                .frame(width: 42, height: 42)
                                                .cornerRadius(6)
                                            }
                                            
                                            VStack(alignment: .leading, spacing: 3) {
                                                Text(playlist.name)
                                                    .font(.system(size: 12, weight: .semibold))
                                                    .foregroundColor(.white)
                                                    .lineLimit(1)
                                                
                                                Text("\(playlist.trackCount) songs")
                                                    .font(.system(size: 10))
                                                    .foregroundColor(.gray)
                                            }
                                            
                                            Spacer()
                                            
                                            // Direct Play Button
                                            Button(action: {
                                                store.playContext(uri: "spotify:playlist:\(playlist.id)")
                                            }) {
                                                Image(systemName: "play.circle.fill")
                                                    .font(.system(size: 18))
                                                    .foregroundColor(.winampOrange)
                                            }
                                            .buttonStyle(.plain)
                                            .opacity(hoverPlaylistId == playlist.id ? 1 : 0)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(hoverPlaylistId == playlist.id ? Color.white.opacity(0.06) : Color.clear)
                                        )
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            store.fetchPlaylistTracks(id: playlist.id, name: playlist.name, artworkUrl: playlist.artworkUrl)
                                        }
                                        .onHover { isHovered in
                                            hoverPlaylistId = isHovered ? playlist.id : nil
                                        }
                                    }
                                    .padding(.horizontal, 8)
                                }
                            }
                        }
                    } else {
                        // Discover View (Featured, New Releases, Recommendations)
                        ScrollView {
                            VStack(alignment: .leading, spacing: 20) {
                                // Recommended for You (Compact)
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Recommended for You")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                    
                                    if store.recommendedTracks.isEmpty {
                                        Text("Play more tracks on Spotify to load recommendations.")
                                            .font(.system(size: 11))
                                            .foregroundColor(.gray)
                                            .padding(.horizontal, 16)
                                    } else {
                                        LazyVStack(spacing: 4) {
                                            ForEach(store.recommendedTracks) { track in
                                                HStack(spacing: 10) {
                                                    if !track.artworkUrl.isEmpty, let url = URL(string: track.artworkUrl) {
                                                        AsyncImage(url: url) { image in
                                                            image.resizable()
                                                        } placeholder: {
                                                            Color.gray.opacity(0.2)
                                                        }
                                                        .frame(width: 32, height: 32)
                                                        .cornerRadius(4)
                                                    } else {
                                                        ZStack {
                                                            Color.gray.opacity(0.2)
                                                            Image(systemName: "music.note")
                                                                .foregroundColor(.gray)
                                                        }
                                                        .frame(width: 32, height: 32)
                                                        .cornerRadius(4)
                                                    }
                                                    
                                                    VStack(alignment: .leading, spacing: 2) {
                                                        Text(track.name)
                                                            .font(.system(size: 11, weight: .semibold))
                                                            .foregroundColor(.white)
                                                            .lineLimit(1)
                                                        Text(track.artist)
                                                            .font(.system(size: 9))
                                                            .foregroundColor(.gray)
                                                            .lineLimit(1)
                                                    }
                                                    
                                                    Spacer()
                                                    
                                                    if hoverTrackUri == track.uri {
                                                        Button(action: {
                                                            store.playTrack(uri: track.uri)
                                                        }) {
                                                            Image(systemName: "play.fill")
                                                                .font(.system(size: 9))
                                                                .foregroundColor(.winampOrange)
                                                        }
                                                        .buttonStyle(.plain)
                                                    }
                                                    
                                                    Menu {
                                                        Button(action: {
                                                            store.playTrack(uri: track.uri)
                                                        }) {
                                                            Label("Play Now", systemImage: "play.fill")
                                                        }
                                                        
                                                        Button(action: {
                                                            store.addToQueue(uri: track.uri)
                                                        }) {
                                                            Label("Add to Queue", systemImage: "text.insert")
                                                        }
                                                        
                                                        if !store.playlists.isEmpty {
                                                            Menu("Add to Playlist") {
                                                                ForEach(store.playlists) { playlist in
                                                                    Button(playlist.name) {
                                                                        store.addTrackToPlaylist(trackUri: track.uri, playlistId: playlist.id)
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    } label: {
                                                        Image(systemName: "ellipsis")
                                                            .font(.system(size: 11, weight: .bold))
                                                            .foregroundColor(.gray)
                                                            .padding(4)
                                                    }
                                                    .menuStyle(.borderlessButton)
                                                    .frame(width: 16)
                                                }
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 6)
                                                        .fill(hoverTrackUri == track.uri ? Color.white.opacity(0.05) : Color.clear)
                                                )
                                                .onHover { isHovered in
                                                    hoverTrackUri = isHovered ? track.uri : nil
                                                }
                                            }
                                        }
                                        .padding(.horizontal, 8)
                                    }
                                }
                                
                                // Featured Playlists (Compact)
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Featured Playlists")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                    
                                    if store.featuredPlaylists.isEmpty {
                                        Text("No featured playlists loaded.")
                                            .font(.system(size: 11))
                                            .foregroundColor(.gray)
                                            .padding(.horizontal, 16)
                                    } else {
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 12) {
                                                ForEach(store.featuredPlaylists) { playlist in
                                                    Button(action: {
                                                        store.fetchPlaylistTracks(id: playlist.id, name: playlist.name, artworkUrl: playlist.artworkUrl)
                                                    }) {
                                                        VStack(alignment: .leading, spacing: 6) {
                                                            if !playlist.artworkUrl.isEmpty, let url = URL(string: playlist.artworkUrl) {
                                                                AsyncImage(url: url) { image in
                                                                    image.resizable()
                                                                } placeholder: {
                                                                    Color.gray.opacity(0.2)
                                                                }
                                                                .frame(width: 80, height: 80)
                                                                .cornerRadius(6)
                                                            } else {
                                                                ZStack {
                                                                    Color.gray.opacity(0.2)
                                                                    Image(systemName: "music.note.list")
                                                                        .foregroundColor(.gray)
                                                                }
                                                                .frame(width: 80, height: 80)
                                                                .cornerRadius(6)
                                                            }
                                                            Text(playlist.name)
                                                                .font(.system(size: 10, weight: .semibold))
                                                                .foregroundColor(.white)
                                                                .lineLimit(1)
                                                                .frame(width: 80, alignment: .leading)
                                                        }
                                                    }
                                                    .buttonStyle(.plain)
                                                }
                                            }
                                            .padding(.horizontal, 16)
                                        }
                                    }
                                }
                                
                                // New Releases (Compact)
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("New Releases")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                    
                                    if store.newReleases.isEmpty {
                                        Text("No new releases loaded.")
                                            .font(.system(size: 11))
                                            .foregroundColor(.gray)
                                            .padding(.horizontal, 16)
                                    } else {
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 12) {
                                                ForEach(store.newReleases) { album in
                                                    Button(action: {
                                                        store.playContext(uri: album.uri)
                                                    }) {
                                                        VStack(alignment: .leading, spacing: 6) {
                                                            if !album.artworkUrl.isEmpty, let url = URL(string: album.artworkUrl) {
                                                                AsyncImage(url: url) { image in
                                                                    image.resizable()
                                                                } placeholder: {
                                                                    Color.gray.opacity(0.2)
                                                                }
                                                                .frame(width: 80, height: 80)
                                                                .cornerRadius(6)
                                                            } else {
                                                                ZStack {
                                                                    Color.gray.opacity(0.2)
                                                                    Image(systemName: "album")
                                                                        .foregroundColor(.gray)
                                                                }
                                                                .frame(width: 80, height: 80)
                                                                .cornerRadius(6)
                                                            }
                                                            Text(album.name)
                                                                .font(.system(size: 10, weight: .semibold))
                                                                .foregroundColor(.white)
                                                                .lineLimit(1)
                                                                .frame(width: 80, alignment: .leading)
                                                            Text(album.artist)
                                                                .font(.system(size: 8))
                                                                .foregroundColor(.gray)
                                                                .lineLimit(1)
                                                                .frame(width: 80, alignment: .leading)
                                                        }
                                                    }
                                                    .buttonStyle(.plain)
                                                }
                                            }
                                            .padding(.horizontal, 16)
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 12)
                        }
                    }
                }
                .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)))
            }
        }
        .onAppear {
            store.fetchWebPlaylists()
        }
    }
    
    private func handleCreatePlaylist() {
        let trimmedName = newPlaylistName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        store.createPlaylist(name: trimmedName)
        newPlaylistName = ""
        withAnimation {
            showCreateField = false
        }
    }
}

// MARK: - Tone Arm Custom View
struct ToneArmView: View {
    let isTrackLoaded: Bool
    let progress: Double
    
    var body: some View {
        let angle = isTrackLoaded ? (-6.0 + progress * 36.0) : -25.0
        
        VStack(spacing: 0) {
            // Pivot base circle
            Circle()
                .fill(Color(white: 0.3))
                .frame(width: 22, height: 22)
                .overlay(Circle().stroke(Color.black.opacity(0.6), lineWidth: 2))
                .shadow(radius: 2)
            
            // Arm metal rod
            RoundedRectangle(cornerRadius: 1)
                .fill(LinearGradient(colors: [Color(white: 0.8), Color(white: 0.5)], startPoint: .top, endPoint: .bottom))
                .frame(width: 4, height: 95)
                .offset(y: -4)
            
            // Cartridge/needle head
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.winampOrange)
                .frame(width: 10, height: 18)
                .offset(y: -8)
                .shadow(radius: 1)
        }
        .rotationEffect(.degrees(angle), anchor: .top)
        .offset(x: 100, y: -45)
        .animation(.spring(response: 0.7, dampingFraction: 0.8), value: angle)
    }
}

// MARK: - Full Screen Player View
struct FullScreenPlayerView: View {
    @Bindable var store: SpotifyStore
    @State private var rotationAngle: Double = 0.0
    @State private var lyricTimer: Timer?
    @State private var activeLineId: UUID? = nil
    
    @State private var isDraggingVinyl = false
    @State private var lastDragAngle: Double = 0.0
    @State private var dragPositionAccumulator: Double = 0.0
    
    private var activeDeviceName: String {
        store.devices.first(where: { $0.isActive || $0.id == store.activeDeviceId })?.name ?? ""
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background Ambient Glow
                if store.enableAmbientGlow, !store.artworkUrl.isEmpty, let url = URL(string: store.artworkUrl) {
                    AsyncImage(url: url) { image in
                        image.resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.black
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                    .blur(radius: 80)
                    .opacity(0.5)
                    .overlay(Color.black.opacity(0.55))
                    .edgesIgnoringSafeArea(.all)
                } else {
                    LinearGradient(
                        colors: [Color(red: 0.04, green: 0.04, blue: 0.06), Color(red: 0.08, green: 0.07, blue: 0.12)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .edgesIgnoringSafeArea(.all)
                }
                
                VStack(spacing: 0) {
                    // Header Bar
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("MUZEEBRA PLAYER")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(.winampOrange)
                            if !activeDeviceName.isEmpty {
                                Text("Playing on \(activeDeviceName)")
                                    .font(.system(size: 11))
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        Spacer()
                        
                        // Action Quick Controls
                        HStack(spacing: 16) {
                            Button(action: {
                                withAnimation {
                                    store.enableVinylRotation.toggle()
                                }
                            }) {
                                Image(systemName: "circle.circle")
                                    .font(.system(size: 13))
                                    .foregroundColor(store.enableVinylRotation ? .winampOrange : .gray)
                            }
                            .help("Toggle Vinyl Rotation")
                            
                            Button(action: {
                                withAnimation {
                                    store.enableAmbientGlow.toggle()
                                }
                            }) {
                                Image(systemName: "sun.max.fill")
                                    .font(.system(size: 13))
                                    .foregroundColor(store.enableAmbientGlow ? .winampOrange : .gray)
                            }
                            .help("Toggle Ambient Glow")
                            
                            Button(action: {
                                withAnimation {
                                    store.enableLyricsSync.toggle()
                                }
                            }) {
                                Image(systemName: "music.mic")
                                    .font(.system(size: 13))
                                    .foregroundColor(store.enableLyricsSync ? .winampOrange : .gray)
                            }
                            .help("Toggle Lyrics Sync")
                            
                            Button(action: {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                    store.showFullScreenPlayer = false
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 32)
                    .padding(.bottom, 20)
                    
                    // Main Split Pane
                    HStack(spacing: 48) {
                        // Left Column: Vinyl Record Player Card
                        VStack(spacing: 16) {
                            Spacer()
                                .frame(height: 30)
                            
                            // Square Album Art above the record player
                            Group {
                                if !store.artworkUrl.isEmpty, let url = URL(string: store.artworkUrl) {
                                    AsyncImage(url: url) { image in
                                        image.resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.white.opacity(0.05))
                                            .overlay(ProgressView().controlSize(.small))
                                    }
                                } else {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white.opacity(0.03))
                                        .overlay(
                                            Image(systemName: "music.note")
                                                .font(.system(size: 50))
                                                .foregroundColor(.gray.opacity(0.4))
                                        )
                                }
                            }
                            .frame(width: 240, height: 240)
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.55), radius: 18, x: 0, y: 12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                            .padding(.top, 10)
                            
                            
                            // Vinyl disc wrapper
                            ZStack(alignment: .center) {
                                // Vinyl disc interactive group (rotates and tracks drag)
                                ZStack(alignment: .center) {
                                    // Black vinyl body
                                    Circle()
                                        .fill(Color(red: 0.05, green: 0.05, blue: 0.05))
                                        .frame(width: 280, height: 280)
                                    
                                    // Vinyl Grooves
                                    ForEach(0..<10) { i in
                                        Circle()
                                            .stroke(Color.white.opacity(0.04), lineWidth: 1)
                                            .frame(width: CGFloat(130 + i * 14), height: CGFloat(130 + i * 14))
                                    }
                                    
                                    // Center Album Art Label
                                    if !store.artworkUrl.isEmpty, let url = URL(string: store.artworkUrl) {
                                        AsyncImage(url: url) { image in
                                            image.resizable()
                                                .aspectRatio(contentMode: .fill)
                                        } placeholder: {
                                            Color.gray.opacity(0.2)
                                        }
                                        .frame(width: 110, height: 110)
                                        .clipShape(Circle())
                                        .rotationEffect(.degrees(rotationAngle))
                                    }
                                    
                                    // Center Spindle Hole
                                    Circle()
                                        .fill(Color(red: 0.08, green: 0.08, blue: 0.08))
                                        .frame(width: 14, height: 14)
                                    Circle()
                                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                                        .frame(width: 15, height: 15)
                                }
                                .frame(width: 280, height: 280)
                                .shadow(color: .black.opacity(0.7), radius: 25, x: 0, y: 15)
                                .contentShape(Circle())
                                .gesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { gesture in
                                            if !isDraggingVinyl {
                                                isDraggingVinyl = true
                                                store.isDraggingProgress = true
                                                let dx = gesture.startLocation.x - 140.0
                                                let dy = gesture.startLocation.y - 140.0
                                                lastDragAngle = atan2(dy, dx) * 180.0 / .pi
                                                dragPositionAccumulator = store.positionMs
                                            }
                                            
                                            let dx = gesture.location.x - 140.0
                                            let dy = gesture.location.y - 140.0
                                            let currentAngle = atan2(dy, dx) * 180.0 / .pi
                                            
                                            var deltaAngle = currentAngle - lastDragAngle
                                            if deltaAngle > 180 {
                                                deltaAngle -= 360
                                            } else if deltaAngle < -180 {
                                                deltaAngle += 360
                                            }
                                            
                                            lastDragAngle = currentAngle
                                            rotationAngle += deltaAngle
                                            
                                            // 1 degree rotation = 35 ms change
                                            let deltaMs = deltaAngle * 35.0
                                            dragPositionAccumulator = max(0.0, min(Double(store.durationMs), dragPositionAccumulator + deltaMs))
                                            store.positionMs = dragPositionAccumulator
                                        }
                                        .onEnded { _ in
                                            isDraggingVinyl = false
                                            store.isDraggingProgress = false
                                            let targetProgress = store.positionMs / Double(max(1, store.durationMs))
                                            store.seek(to: targetProgress)
                                        }
                                )
                                
                                // Animated Tone-arm Needle sits on top of vinyl disc
                                let progress = Double(store.positionMs) / Double(max(1, store.durationMs))
                                let isTrackLoaded = !store.trackName.isEmpty && 
                                                    store.trackName != "No Track Playing" && 
                                                    store.trackName != "Spotify is Closed" && 
                                                    store.trackName != "Not Logged In"
                                ToneArmView(isTrackLoaded: isTrackLoaded, progress: progress)
                            }
                            .frame(width: 280, height: 280)
                            .padding(.vertical, 10)
                            
                            // Metadata Details
                            VStack(spacing: 6) {
                                Text(store.trackName)
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                    .multilineTextAlignment(.center)
                                
                                Button(action: {
                                    if !store.artistId.isEmpty {
                                        store.fetchArtistDetails(id: store.artistId)
                                        store.showFullScreenPlayer = false
                                    }
                                }) {
                                    Text(store.artist)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.winampOrange)
                                        .underline()
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 16)
                            
                            // Timeline Progress Slider
                            VStack(spacing: 6) {
                                Slider(value: Binding(
                                    get: { store.positionMs / Double(max(1, store.durationMs)) },
                                    set: { store.seek(to: $0) }
                                ), in: 0.0...1.0)
                                .accentColor(.winampOrange)
                                
                                HStack {
                                    Text(formatDuration(store.positionMs))
                                    Spacer()
                                    Text(formatDuration(store.durationMs))
                                }
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.gray)
                            }
                            .padding(.horizontal, 20)
                            
                            // Playback Controls
                            HStack(spacing: 28) {
                                Button(action: { store.toggleShuffle() }) {
                                    Image(systemName: "shuffle")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(store.shuffleState ? .winampOrange : .gray)
                                }
                                
                                Button(action: { store.previousTrack() }) {
                                    Image(systemName: "backward.fill")
                                        .font(.system(size: 20))
                                }
                                
                                Button(action: { store.playPause() }) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.winampOrange)
                                            .frame(width: 58, height: 58)
                                            .shadow(color: .winampOrange.opacity(0.3), radius: 6)
                                        Image(systemName: store.isPlaying ? "pause.fill" : "play.fill")
                                            .font(.system(size: 22))
                                            .foregroundColor(.black)
                                            .offset(x: store.isPlaying ? 0 : 2)
                                    }
                                }
                                
                                Button(action: { store.nextTrack() }) {
                                    Image(systemName: "forward.fill")
                                        .font(.system(size: 20))
                                }
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(.white)
                            .padding(.bottom, 20)
                            
                            Spacer()
                        }
                        .frame(width: 320)
                        
                        Divider().background(Color.white.opacity(0.1))
                        
                        // Right Column: Scrolling Synced Lyrics
                        VStack(alignment: .center, spacing: 16) {
                            HStack {
                                Spacer()
                                Image(systemName: "music.mic")
                                    .foregroundColor(.winampOrange)
                                Text("LIVE LYRICS")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(.winampOrange)
                                Spacer()
                            }
                            .padding(.horizontal, 10)
                            
                            if store.isLyricsLoading {
                                Spacer()
                                HStack {
                                    Spacer()
                                    ProgressView().controlSize(.small)
                                    Text("Searching lyrics...")
                                        .font(.system(size: 13))
                                        .foregroundColor(.gray)
                                        .padding(.leading, 8)
                                    Spacer()
                                }
                                Spacer()
                            } else if store.lyricsSyncedLines.isEmpty && store.lyricsText.isEmpty {
                                Spacer()
                                VStack(spacing: 16) {
                                    Image(systemName: "music.mic.system.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray.opacity(0.3))
                                    Text("No lyrics found for this track")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.gray)
                                }
                                .frame(maxWidth: .infinity)
                                Spacer()
                            } else if !store.lyricsSyncedLines.isEmpty {
                                ScrollViewReader { scrollProxy in
                                    ScrollView(showsIndicators: false) {
                                        LazyVStack(alignment: .center, spacing: 26) {
                                            ForEach(store.lyricsSyncedLines) { line in
                                                Text(line.text)
                                                    .font(.system(size: activeLineId == line.id ? 26 : 22, weight: activeLineId == line.id ? .bold : .semibold, design: .rounded))
                                                    .foregroundColor(activeLineId == line.id ? .winampOrange : .white.opacity(0.35))
                                                    .shadow(color: activeLineId == line.id ? .winampOrange.opacity(0.4) : .clear, radius: 4)
                                                    .scaleEffect(activeLineId == line.id ? 1.05 : 1.0, anchor: .center)
                                                    .multilineTextAlignment(.center)
                                                    .frame(maxWidth: .infinity, alignment: .center)
                                                    .padding(.horizontal, 10)
                                                    .id(line.id)
                                                    .contentShape(Rectangle())
                                                    .onTapGesture {
                                                        store.seek(to: line.timeMs / Double(max(1, store.durationMs)))
                                                    }
                                            }
                                        }
                                        .padding(.vertical, 200) // High padding to allow middle lock
                                    }
                                    .onChange(of: activeLineId) { _, newValue in
                                        if store.enableLyricsSync, let lineId = newValue {
                                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                                scrollProxy.scrollTo(lineId, anchor: .center)
                                            }
                                        }
                                    }
                                }
                            } else {
                                // Fallback for plain text lyrics
                                ScrollView(showsIndicators: false) {
                                    Text(store.lyricsText)
                                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white.opacity(0.8))
                                        .multilineTextAlignment(.center)
                                        .lineSpacing(12)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                        .padding(.horizontal, 20)
                                        .padding(.top, 80) // Pushed down so it is centered vertically
                                        .padding(.bottom, 80)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
                }
            }
        }
        .onAppear {
            startVinylTimer()
        }
        .onDisappear {
            lyricTimer?.invalidate()
        }
        .onChange(of: store.positionMs) { _, newPosition in
            updateLyricsHighlight(for: newPosition)
        }
    }
    
    private func startVinylTimer() {
        lyricTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            if store.isPlaying && store.enableVinylRotation && !isDraggingVinyl {
                rotationAngle += 1.2
                if rotationAngle >= 360 {
                    rotationAngle = 0
                }
            }
        }
    }
    
    private func updateLyricsHighlight(for position: Double) {
        let lines = store.lyricsSyncedLines
        guard !lines.isEmpty else { return }
        
        var matchId: UUID? = nil
        for i in 0..<lines.count {
            let lineTime = lines[i].timeMs
            let nextLineTime = i < lines.count - 1 ? lines[i+1].timeMs : Double.infinity
            
            if position >= lineTime && position < nextLineTime {
                matchId = lines[i].id
                break
            }
        }
        if matchId == nil, let first = lines.first, position < first.timeMs {
            matchId = first.id
        }
        if activeLineId != matchId {
            activeLineId = matchId
        }
    }
    
    private func formatDuration(_ ms: Double) -> String {
        let seconds = Int(ms) / 1000
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
    
    private func formatDuration(_ ms: Int) -> String {
        let seconds = ms / 1000
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - Artist Detail View
struct ArtistDetailView: View {
    var store: SpotifyStore
    let artistDetails: SpotifyArtistDetails
    @State private var hoverTrackUri: String? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Header bar
            HStack {
                Button(action: {
                    store.activeArtistDetails = nil
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .bold))
                        Text("Back")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.winampOrange)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Text("ARTIST PROFILE")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    // Artist banner profile details
                    HStack(spacing: 16) {
                        if !artistDetails.artworkUrl.isEmpty, let url = URL(string: artistDetails.artworkUrl) {
                            AsyncImage(url: url) { image in
                                image.resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Color.gray.opacity(0.2)
                            }
                            .frame(width: 74, height: 74)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.winampOrange.opacity(0.6), lineWidth: 1.5))
                            .shadow(radius: 4)
                        } else {
                            ZStack {
                                Color.gray.opacity(0.2)
                                Image(systemName: "person.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.gray)
                            }
                            .frame(width: 74, height: 74)
                            .clipShape(Circle())
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(artistDetails.name)
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            HStack(spacing: 8) {
                                Text("\(formatFollowers(artistDetails.followersCount)) followers")
                                    .font(.system(size: 11))
                                    .foregroundColor(.gray)
                                
                                if let firstGenre = artistDetails.genres.first {
                                    Text("•")
                                        .foregroundColor(.gray.opacity(0.5))
                                    Text(firstGenre.capitalized)
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(.winampOrange.opacity(0.85))
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    // Top tracks section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Popular Tracks")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 4)
                        
                        ForEach(Array(artistDetails.topTracks.enumerated()), id: \.offset) { idx, track in
                            Button(action: {
                                store.playTrack(uri: track.uri)
                            }) {
                                HStack(spacing: 12) {
                                    Text("\(idx + 1)")
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundColor(.gray)
                                        .frame(width: 14)
                                    
                                    if !track.artworkUrl.isEmpty, let url = URL(string: track.artworkUrl) {
                                        AsyncImage(url: url) { image in
                                            image.resizable()
                                        } placeholder: {
                                            Color.gray.opacity(0.2)
                                        }
                                        .frame(width: 30, height: 30)
                                        .cornerRadius(4)
                                    } else {
                                        ZStack {
                                            Color.gray.opacity(0.2)
                                            Image(systemName: "music.note")
                                                .foregroundColor(.gray)
                                        }
                                        .frame(width: 30, height: 30)
                                        .cornerRadius(4)
                                    }
                                    
                                    Text(track.name)
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                    
                                    Spacer()
                                    
                                    if hoverTrackUri == track.uri {
                                        Image(systemName: "play.fill")
                                            .font(.system(size: 9))
                                            .foregroundColor(.winampOrange)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(hoverTrackUri == track.uri ? Color.white.opacity(0.05) : Color.clear)
                                )
                            }
                            .buttonStyle(.plain)
                            .onHover { isHovered in
                                hoverTrackUri = isHovered ? track.uri : nil
                            }
                        }
                    }
                    
                    // Albums Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Albums")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(artistDetails.albums) { album in
                                    Button(action: {
                                        store.playContext(uri: album.uri)
                                    }) {
                                        VStack(alignment: .leading, spacing: 6) {
                                            if !album.artworkUrl.isEmpty, let url = URL(string: album.artworkUrl) {
                                                AsyncImage(url: url) { image in
                                                    image.resizable()
                                                } placeholder: {
                                                    Color.gray.opacity(0.2)
                                                }
                                                .frame(width: 84, height: 84)
                                                .cornerRadius(6)
                                                .shadow(radius: 2)
                                            } else {
                                                ZStack {
                                                    Color.gray.opacity(0.2)
                                                    Image(systemName: "music.note.list")
                                                        .foregroundColor(.gray)
                                                }
                                                .frame(width: 84, height: 84)
                                                .cornerRadius(6)
                                            }
                                            Text(album.name)
                                                .font(.system(size: 10, weight: .semibold))
                                                .foregroundColor(.white)
                                                .lineLimit(1)
                                                .frame(width: 84, alignment: .leading)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func formatFollowers(_ total: Int) -> String {
        if total >= 1_000_000 {
            return String(format: "%.1fM", Double(total) / 1_000_000.0)
        } else if total >= 1_000 {
            return String(format: "%.1fK", Double(total) / 1_000.0)
        } else {
            return "\(total)"
        }
    }
}

// MARK: - Picture-in-Picture Mini Player View
struct MiniPlayerView: View {
    @Bindable var store: SpotifyStore
    
    var body: some View {
        HStack(spacing: 12) {
            // Album art
            if !store.artworkUrl.isEmpty, let url = URL(string: store.artworkUrl) {
                AsyncImage(url: url) { image in
                    image.resizable()
                } placeholder: {
                    ZStack {
                        Color.gray.opacity(0.15)
                        ProgressView().controlSize(.small)
                    }
                }
                .frame(width: 72, height: 72)
                .cornerRadius(8)
                .shadow(radius: 4)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.03))
                    Image(systemName: "music.note")
                        .font(.system(size: 24))
                        .foregroundColor(.gray)
                }
                .frame(width: 72, height: 72)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                // Title and exit button
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(store.trackName)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        Text(store.artist)
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Exit Mini button
                    Button(action: { store.toggleMiniPlayer() }) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 4)
                }
                
                // Mini progress bar
                let progress = store.durationMs > 0 ? store.positionMs / Double(store.durationMs) : 0.0
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 3)
                        
                        Capsule()
                            .fill(LinearGradient(colors: [.winampOrange, .winampRed], startPoint: .leading, endPoint: .trailing))
                            .frame(width: geometry.size.width * CGFloat(progress), height: 3)
                    }
                }
                .frame(height: 3)
                .padding(.vertical, 4)
                
                // Controls row
                HStack(spacing: 16) {
                    Button(action: { store.previousTrack() }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 14))
                    }
                    
                    Button(action: { store.playPause() }) {
                        Image(systemName: store.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.winampOrange)
                    }
                    
                    Button(action: { store.nextTrack() }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 14))
                    }
                    
                    Spacer()
                    
                    // Sleep timer badge if active
                    if store.isSleepTimerActive {
                        HStack(spacing: 2) {
                            Image(systemName: "timer")
                                .font(.system(size: 8))
                            Text(formatTime(store.sleepTimerSecondsRemaining))
                                .font(.system(size: 8, design: .monospaced))
                        }
                        .foregroundColor(.winampOrange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.winampOrange.opacity(0.1))
                        .cornerRadius(4)
                    }
                }
                .buttonStyle(.plain)
                .foregroundColor(.white)
            }
        }
        .padding(12)
        .frame(width: 320, height: 110)
        .background(
            LinearGradient(
                colors: [Color(red: 0.08, green: 0.08, blue: 0.12), Color(red: 0.12, green: 0.11, blue: 0.18)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - Winamp Graphic Equalizer View
struct EqualizerView: View {
    @Bindable var store: SpotifyStore
    
    var body: some View {
        VStack(spacing: 16) {
            // Header controls
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundColor(.winampOrange)
                    Text("GRAPHIC EQUALIZER")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // EQ Enable switch
                Toggle(isOn: $store.isEqEnabled) {
                    Text("EQ")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.gray)
                }
                .toggleStyle(.switch)
                .controlSize(.small)
                .frame(width: 70)
            }
            .padding(.horizontal, 8)
            
            if store.isLocalMode {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.winampOrange)
                        .font(.system(size: 14))
                    Text("EQ only works in Web Player mode (local Spotify App has no EQ API).")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.winampOrange)
                        .lineLimit(nil)
                        .multilineTextAlignment(.leading)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.winampOrange.opacity(0.1))
                .cornerRadius(6)
                .padding(.horizontal, 8)
            }
            
            // Preset Selector and Preamp info
            HStack {
                Text("Preset:")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.gray)
                
                Picker("", selection: Binding<String>(
                    get: { store.eqPresetName },
                    set: { store.applyEqPreset($0) }
                )) {
                    Text("Flat").tag("Flat")
                    Text("Classical").tag("Classical")
                    Text("Club").tag("Club")
                    Text("Dance").tag("Dance")
                    Text("Laptop").tag("Laptop")
                    Text("Large Hall").tag("Large Hall")
                    Text("Party").tag("Party")
                    Text("Pop").tag("Pop")
                    Text("Reggae").tag("Reggae")
                    Text("Rock").tag("Rock")
                    Text("Soft").tag("Soft")
                    Text("Techno").tag("Techno")
                    Text("Vocal").tag("Vocal")
                }
                .pickerStyle(.menu)
                .frame(width: 125)
                
                Spacer()
                
                Text(String(format: "Preamp: %+.1fdB", store.eqPreamp))
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(.winampOrange)
            }
            .padding(.horizontal, 8)
            .disabled(!store.isEqEnabled)
            .opacity(store.isEqEnabled ? 1.0 : 0.4)
            
            // Sliders grid
            HStack(spacing: 4) {
                // PREAMP
                EqualizerSlider(value: $store.eqPreamp, label: "PRE")
                
                Divider()
                    .background(Color.white.opacity(0.1))
                    .frame(height: 140)
                    .padding(.horizontal, 4)
                
                let labels = ["31", "62", "125", "250", "500", "1K", "2K", "4K", "8K", "16K"]
                ForEach(0..<10) { index in
                    EqualizerSlider(value: $store.eqBands[index], label: labels[index])
                }
            }
            .padding(.vertical, 8)
            .disabled(!store.isEqEnabled)
            .opacity(store.isEqEnabled ? 1.0 : 0.4)
        }
        .padding(12)
        .background(Color.white.opacity(0.02))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}

struct EqualizerSlider: View {
    @Binding var value: Double
    let label: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(String(format: "%+.1f", value))
                .font(.system(size: 8, design: .monospaced))
                .foregroundColor(.gray)
                .frame(height: 10)
            
            GeometryReader { geometry in
                let height = geometry.size.height
                let sliderHeight: CGFloat = 10
                let currentY = height - sliderHeight - ((CGFloat(value) + 12.0) / 24.0 * (height - sliderHeight))
                
                ZStack(alignment: .topLeading) {
                    // Track
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    
                    // Center zero line
                    Rectangle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 8, height: 1)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    
                    // Thumb
                    RoundedRectangle(cornerRadius: 2)
                        .fill(LinearGradient(colors: [.winampOrange, .winampRed], startPoint: .top, endPoint: .bottom))
                        .frame(width: 14, height: sliderHeight)
                        .position(x: geometry.size.width / 2, y: currentY + sliderHeight / 2)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            let locationY = gesture.location.y
                            let pct = 1.0 - max(0.0, min(1.0, locationY / height))
                            value = Double(pct * 24.0) - 12.0
                        }
                )
            }
            .frame(width: 18, height: 120)
            
            Text(label)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Audio Vibe & Insights View
struct AudioInsightsView: View {
    @Bindable var store: SpotifyStore
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "waveform.path.ecg")
                    .foregroundColor(.winampOrange)
                Text("AUDIO VIBE & BEATS")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal, 4)
            
            if store.isAudioFeaturesLoading {
                Spacer()
                ProgressView().controlSize(.small)
                Text("Analyzing vibe...")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                Spacer()
            } else if !store.hasAudioFeatures {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "waveform.path.ecg.rectangle")
                        .font(.system(size: 36))
                        .foregroundColor(.gray.opacity(0.3))
                    Text("Vibe analysis is only available for tracks played in Cloud Mode. Please play a track to analyze.")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                Spacer()
            } else {
                VStack(spacing: 16) {
                    VStack(spacing: 4) {
                        Text(store.trackName)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text(getVibeProfileName())
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(.winampOrange)
                    }
                    .padding(.vertical, 4)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        VibeMetricCard(title: "Tempo (BPM)", value: String(format: "%.0f", store.tempo), percentage: store.tempo / 200.0, icon: "headphones", desc: "Speed")
                        VibeMetricCard(title: "Energy", value: String(format: "%.0f%%", store.energy * 100.0), percentage: store.energy, icon: "bolt.fill", desc: "Intensity & Noise")
                        VibeMetricCard(title: "Danceability", value: String(format: "%.0f%%", store.danceability * 100.0), percentage: store.danceability, icon: "waveform", desc: "Rhythm suitability")
                        VibeMetricCard(title: "Happiness", value: String(format: "%.0f%%", store.valence * 100.0), percentage: store.valence, icon: "sun.max.fill", desc: "Cheerfulness")
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Label("Acousticness", systemImage: "guitars.fill")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                            Spacer()
                            Text(String(format: "%.0f%%", store.acousticness * 100.0))
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundColor(.gray)
                        }
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.white.opacity(0.05))
                                    .frame(height: 4)
                                Capsule()
                                    .fill(LinearGradient(colors: [.winampOrange, .winampRed], startPoint: .leading, endPoint: .trailing))
                                    .frame(width: geometry.size.width * CGFloat(store.acousticness), height: 4)
                            }
                        }
                        .frame(height: 4)
                        
                        Text(store.acousticness > 0.5 ? "Acoustic / organic instruments detected." : "Synthesized / electronic beats detected.")
                            .font(.system(size: 8))
                            .foregroundColor(.gray)
                    }
                    .padding(8)
                    .background(Color.white.opacity(0.02))
                    .cornerRadius(6)
                }
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.02))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
    
    private func getVibeProfileName() -> String {
        let energy = store.energy
        let valence = store.valence
        
        if energy > 0.7 && valence > 0.6 {
            return "🔥 Energetic & Uplifting"
        } else if energy > 0.7 && valence <= 0.4 {
            return "💥 Intense & Aggressive"
        } else if energy <= 0.4 && valence > 0.6 {
            return "☀️ Chill & Positive"
        } else if energy <= 0.4 && valence <= 0.4 {
            return "🌙 Melancholic & Atmospheric"
        } else {
            return "🎵 Balanced Vibe"
        }
    }
}

struct VibeMetricCard: View {
    let title: String
    let value: String
    let percentage: Double
    let icon: String
    let desc: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.winampOrange)
                    .font(.system(size: 11))
                Text(title)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.gray)
                Spacer()
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text(desc)
                    .font(.system(size: 8))
                    .foregroundColor(.gray)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.05))
                        .frame(height: 3)
                    Capsule()
                        .fill(Color.winampOrange)
                        .frame(width: geometry.size.width * CGFloat(min(1.0, percentage)), height: 3)
                        .shadow(color: Color.winampOrange.opacity(0.4), radius: 2)
                }
            }
            .frame(height: 3)
        }
        .padding(8)
        .background(Color.white.opacity(0.02))
        .cornerRadius(6)
    }
}

// MARK: - Online Sync Settings View
struct OnlineSyncSettingsView: View {
    @Bindable var store: SpotifyStore
    @State private var email = ""
    @State private var password = ""
    @State private var statusMessage = ""
    @State private var isError = false
    @State private var isLoading = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "cloud.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.winampOrange)
                Text("Online Sync & Account")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Toggle("Enable Online Streaming Sync", isOn: $store.onlineSyncEnabled)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                    .toggleStyle(.switch)
                    .controlSize(.small)
                
                Text("Sync playback history online to save streaming logs and compile data analytics.")
                    .font(.system(size: 9))
                    .foregroundColor(.gray)
                    .padding(.bottom, 4)
                
                if store.onlineSyncEnabled {
                    Divider().background(Color.white.opacity(0.05))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Server URL")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.gray)
                        
                        TextField("http://localhost:3000", text: $store.onlineServerUrl)
                            .textFieldStyle(.plain)
                            .font(.system(size: 11))
                            .padding(6)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(4)
                            .foregroundColor(.white)
                    }
                    
                    if store.isOnlineLoggedIn {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Logged in as:")
                                    .font(.system(size: 9))
                                    .foregroundColor(.gray)
                                Text(store.onlineUserEmail)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.winampOrange)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                store.logoutOnlineUser()
                                statusMessage = "Logged out successfully"
                                isError = false
                            }) {
                                Text("Log Out")
                                    .font(.system(size: 10, weight: .bold))
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 10)
                                    .background(Color.red.opacity(0.2))
                                    .foregroundColor(.red)
                                    .cornerRadius(4)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(8)
                        .background(Color.white.opacity(0.02))
                        .cornerRadius(6)
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.gray)
                            TextField("user@example.com", text: $email)
                                .textFieldStyle(.plain)
                                .font(.system(size: 11))
                                .padding(6)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(4)
                                .foregroundColor(.white)
                            
                            Text("Password")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.gray)
                            SecureField("••••••••", text: $password)
                                .textFieldStyle(.plain)
                                .font(.system(size: 11))
                                .padding(6)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(4)
                                .foregroundColor(.white)
                            
                            HStack(spacing: 8) {
                                Button(action: {
                                    guard !email.isEmpty && !password.isEmpty else {
                                        statusMessage = "Email/Password required"
                                        isError = true
                                        return
                                    }
                                    isLoading = true
                                    statusMessage = "Logging in..."
                                    isError = false
                                    
                                    store.loginOnlineUser(email: email, password: password) { success, errMsg in
                                        isLoading = false
                                        if success {
                                            statusMessage = "Logged in successfully!"
                                            isError = false
                                            email = ""
                                            password = ""
                                        } else {
                                            statusMessage = errMsg ?? "Login failed"
                                            isError = true
                                        }
                                    }
                                }) {
                                    Text("Log In")
                                        .font(.system(size: 10, weight: .bold))
                                        .padding(.vertical, 6)
                                        .frame(maxWidth: .infinity)
                                        .background(Color.winampOrange)
                                        .foregroundColor(.white)
                                        .cornerRadius(4)
                                }
                                .buttonStyle(.plain)
                                .disabled(isLoading)
                                
                                Button(action: {
                                    guard !email.isEmpty && !password.isEmpty else {
                                        statusMessage = "Email/Password required"
                                        isError = true
                                        return
                                    }
                                    isLoading = true
                                    statusMessage = "Registering..."
                                    isError = false
                                    
                                    store.registerOnlineUser(email: email, password: password) { success, errMsg in
                                        isLoading = false
                                        if success {
                                            statusMessage = "Registration successful! Logging in..."
                                            store.loginOnlineUser(email: email, password: password) { loginSuccess, loginErrMsg in
                                                if loginSuccess {
                                                    statusMessage = "Registered and logged in!"
                                                    isError = false
                                                    email = ""
                                                    password = ""
                                                } else {
                                                    statusMessage = "Registered, but login failed: \(loginErrMsg ?? "")"
                                                    isError = true
                                                }
                                            }
                                        } else {
                                            statusMessage = errMsg ?? "Registration failed"
                                            isError = true
                                        }
                                    }
                                }) {
                                    Text("Register")
                                        .font(.system(size: 10, weight: .semibold))
                                        .padding(.vertical, 6)
                                        .frame(maxWidth: .infinity)
                                        .background(Color.white.opacity(0.1))
                                        .foregroundColor(.white)
                                        .cornerRadius(4)
                                }
                                .buttonStyle(.plain)
                                .disabled(isLoading)
                            }
                        }
                    }
                    
                    if !statusMessage.isEmpty {
                        Text(statusMessage)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(isError ? .red : .green)
                            .padding(.top, 4)
                    }
                }
            }
            .padding(12)
            .background(Color.white.opacity(0.02))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            )
        }
    }
}

// MARK: - Listening Analytics View
struct AnalyticsView: View {
    @Bindable var store: SpotifyStore
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "chart.bar.xaxis")
                        .foregroundColor(.winampOrange)
                    Text("LISTENING ANALYTICS")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                if store.isOnlineLoggedIn {
                    Button(action: {
                        store.fetchOnlineAnalytics()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            
            if store.isOnlineLoggedIn {
                // Bento Layout
                VStack(spacing: 12) {
                    // Summary card
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("TOTAL PLAYS")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundColor(.gray)
                            Text("\(store.analyticsTotalPlays)")
                                .font(.system(size: 32, weight: .black, design: .rounded))
                                .foregroundColor(.winampOrange)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Color.white.opacity(0.02))
                        .cornerRadius(8)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("MODE DISTRIBUTION")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundColor(.gray)
                            
                            HStack(spacing: 8) {
                                Text("Web: \(store.onlineWebModePlays)")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                                Text("Local: \(store.onlineLocalModePlays)")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.gray)
                            }
                            
                            // Visual bar
                            let total = store.onlineWebModePlays + store.onlineLocalModePlays
                            let webPct = total > 0 ? Double(store.onlineWebModePlays) / Double(total) : 0.5
                            
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.white.opacity(0.05))
                                    Capsule()
                                        .fill(Color.winampOrange)
                                        .frame(width: geo.size.width * CGFloat(webPct))
                                }
                            }
                            .frame(height: 4)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Color.white.opacity(0.02))
                        .cornerRadius(8)
                    }
                    
                    // Top Lists Columns
                    HStack(alignment: .top, spacing: 12) {
                        // Top Tracks
                        VStack(alignment: .leading, spacing: 8) {
                            Text("TOP 5 TRACKS")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(.gray)
                            
                            if store.analyticsTopTracks.isEmpty {
                                Text("No tracks logged yet. Play music to generate stats.")
                                    .font(.system(size: 10))
                                    .foregroundColor(.gray)
                                    .padding(.vertical, 8)
                            } else {
                                ForEach(Array(store.analyticsTopTracks.enumerated()), id: \.1.uri) { index, track in
                                    HStack(spacing: 8) {
                                        Text("\(index + 1)")
                                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                                            .foregroundColor(.winampOrange)
                                            .frame(width: 14, alignment: .leading)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(track.trackName)
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.white)
                                                .lineLimit(1)
                                            Text(track.artist)
                                                .font(.system(size: 8))
                                                .foregroundColor(.gray)
                                                .lineLimit(1)
                                        }
                                        
                                        Spacer()
                                        
                                        Text("\(track.playCount)")
                                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.vertical, 4)
                                    if index < store.analyticsTopTracks.count - 1 {
                                        Divider().background(Color.white.opacity(0.03))
                                    }
                                }
                            }
                        }
                        .padding(12)
                        .background(Color.white.opacity(0.02))
                        .cornerRadius(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Top Artists
                        VStack(alignment: .leading, spacing: 8) {
                            Text("TOP 5 ARTISTS")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(.gray)
                            
                            if store.analyticsTopArtists.isEmpty {
                                Text("No artists logged yet. Play music to generate stats.")
                                    .font(.system(size: 10))
                                    .foregroundColor(.gray)
                                    .padding(.vertical, 8)
                            } else {
                                ForEach(Array(store.analyticsTopArtists.enumerated()), id: \.1.artist) { index, artist in
                                    HStack(spacing: 8) {
                                        Text("\(index + 1)")
                                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                                            .foregroundColor(.winampOrange)
                                            .frame(width: 14, alignment: .leading)
                                        
                                        Text(artist.artist)
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.white)
                                            .lineLimit(1)
                                        
                                        Spacer()
                                        
                                        Text("\(artist.playCount)")
                                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.vertical, 4)
                                    if index < store.analyticsTopArtists.count - 1 {
                                        Divider().background(Color.white.opacity(0.03))
                                    }
                                }
                            }
                        }
                        .padding(12)
                        .background(Color.white.opacity(0.02))
                        .cornerRadius(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "cloud.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.gray.opacity(0.3))
                        .padding(.top, 20)
                    
                    Text("Online Sync Required")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("To see your listening analytics, enable 'Online Sync' and log in or create an account in the Settings tab.")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 24)
                    
                    Button(action: {
                        store.selectedTab = "settings"
                    }) {
                        Text("Go to Settings")
                            .font(.system(size: 11, weight: .bold))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Color.winampOrange)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 20)
                }
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.01))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.02))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}
