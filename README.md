# Muzeebra

Muzeebra is an ultra-lightweight, high-performance native macOS application that functions as a lightweight Spotify client and playback controller. 

By leveraging native macOS frameworks (Swift, SwiftUI, AppKit, WebKit, and Network), Muzeebra runs with a physical memory footprint of only **~15-30 MB of RAM** and near **0% idle CPU**—avoiding the heavy resource overhead of standard Electron-based wrappers.

---

## Key Features

1. **Zero-Configuration Local Mode:**
   - Controls the official Spotify macOS desktop app directly using native AppleScript.
   - Listens to system-wide distributed notifications (`com.spotify.client.PlaybackStateChanged`) for instantaneous state updates with zero polling overhead.
   - Works fully offline and requires no Spotify login or API configuration.

2. **Standalone Web Mode (Built-In Web Player):**
   - Connects to the Spotify Web API for catalog searching, playlist browsing, and device management.
   - **Runs independently of the official Spotify app:** Features a built-in background playback engine that acts as a standalone Spotify Connect output device.
   - **Throttling Prevention:** The player runs inside a borderless, transparent **1x1 background `NSWindow`**. Because the window is technically "on screen" and active, macOS's window server does not suspend its JavaScript execution or audio processes (avoiding typical App Nap throttling seen in hidden `WKWebView` views).

3. **Developer Settings & Portability:**
   - Includes a custom Spotify Client ID override field in Settings. Anyone downloading this app can enter their own credentials.
   - The OAuth redirect server spins up dynamically on local port `5073` and shuts down immediately after catching the authorization code.
   - Fully portable with zero hardcoded file paths. Logs are automatically saved securely in standard macOS caches (`~/Library/Caches/muzeebra.log`).

4. **Resource Monitor & Low Power Mode:**
   - Features a collapsible performance footer displaying real-time physical memory (Resident Set Size via Mach system calls), API request counts, and CPU.
   - **Low Power Mode:** Toggles to slow down background timers and disable equalizer animations, further reducing battery drain.

---

## How to Build & Run

Muzeebra has **zero external dependencies** and compile targets.

### Prerequisites
- macOS 14.0 or later
- Xcode or Swift Command Line Tools

### Developer Compile & Launch
We include helper scripts under `Scripts/` to compile, package, sign, and run the app bundle on your Mac:

```bash
# Build the binary, build the .app structure, codesign ad-hoc, and open it
./Scripts/compile_and_run.sh
```

---

## Spotify API Dashboard Setup (For Web Mode)

If you wish to use the standalone **Web Mode**, you will need a Spotify Developer Client ID.

1. Go to the [Spotify Developer Dashboard](https://developer.spotify.com) and create an app.
2. Under your app settings, add the following **Redirect URI**:
   `http://127.0.0.1:5073/callback`
3. Copy your **Client ID**.
4. In Muzeebra, open the **Settings tab**, expand **Advanced Options**, paste your Client ID, and click **Link Spotify Account** to authenticate.

---

## Repository Structure

- `Package.swift` - SwiftPM Package manifest (v14 target target, 0 external dependencies).
- `Sources/Muzeebra/`
  - `MuzeebraApp.swift` - SwiftUI Application entry point.
  - `SpotifyStore.swift` - Main `@Observable` state coordinator.
  - `SpotifyLocalService.swift` - AppleScript executor for local control.
  - `SpotifyWebService.swift` - OAuth handler and Web API client.
  - `SpotifyWebPlayerWindowController.swift` - Manages the background 1x1 transparent playback window.
  - `MenuBarView.swift` - Glassmorphic main window interface (Now Playing, Search, Settings, Performance Monitor).
- `Scripts/`
  - `package_app.sh` - Packages the compiled binary into a `.app` bundle, injects Info.plist entitlements, and signs it.
  - `compile_and_run.sh` - Development script to clean, rebuild, package, and launch the application.
