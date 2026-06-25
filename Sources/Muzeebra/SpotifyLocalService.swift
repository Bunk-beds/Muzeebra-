import Foundation

class SpotifyLocalService {
    static let shared = SpotifyLocalService()
    
    // Check if local Spotify is running
    var isSpotifyRunning: Bool {
        let script = "application \"Spotify\" is running"
        return executeAppleScript(script) == "true"
    }
    
    // Commands
    func playPause() {
        let script = "tell application \"Spotify\" to playpause"
        _ = executeAppleScript(script)
    }
    
    func nextTrack() {
        let script = "tell application \"Spotify\" to next track"
        _ = executeAppleScript(script)
    }
    
    func previousTrack() {
        let script = "tell application \"Spotify\" to previous track"
        _ = executeAppleScript(script)
    }
    
    func setVolume(_ volume: Int) { // volume is 0..100
        let script = "tell application \"Spotify\" to set sound volume to \(volume)"
        _ = executeAppleScript(script)
    }
    
    func seek(to positionInSeconds: Double) {
        let script = "tell application \"Spotify\" to set player position to \(positionInSeconds)"
        _ = executeAppleScript(script)
    }
    
    func getVolume() -> Int? {
        let script = "tell application \"Spotify\" to sound volume as integer"
        if let res = executeAppleScript(script), let vol = Int(res) {
            return vol
        }
        return nil
    }
    
    func getPlayerPosition() -> Double? {
        let script = "tell application \"Spotify\" to player position as number"
        if let res = executeAppleScript(script), let pos = Double(res) {
            return pos
        }
        return nil
    }
    
    // Fetch now playing state via AppleScript (fallback if notifications not received yet)
    func getPlaybackState() -> LocalPlaybackState? {
        guard isSpotifyRunning else { return nil }
        
        let script = """
        tell application "Spotify"
            if player state is playing then
                set pState to "playing"
            else
                set pState to "paused"
            end if
            try
                set tName to name of current track
                set tArtist to artist of current track
                set tAlbum to album of current track
                set tDur to duration of current track
                set tPos to player position
                set tArt to artwork url of current track
                set tId to id of current track
                return pState & "|" & tName & "|" & tArtist & "|" & tAlbum & "|" & tDur & "|" & tPos & "|" & tArt & "|" & tId
            on error
                return pState & "|Unknown|Unknown|Unknown|0|0.0||"
            end try
        end tell
        """
        
        guard let output = executeAppleScript(script) else { return nil }
        let parts = output.components(separatedBy: "|")
        guard parts.count >= 7 else { return nil }
        
        let isPlaying = parts[0] == "playing"
        let name = parts[1]
        let artist = parts[2]
        let album = parts[3]
        let durationMs = Int(parts[4]) ?? 0
        let positionSec = Double(parts[5]) ?? 0.0
        let artworkUrl = parts[6]
        let trackUri = parts.count > 7 ? parts[7] : ""
        
        return LocalPlaybackState(
            isPlaying: isPlaying,
            trackName: name,
            artist: artist,
            albumName: album,
            durationMs: durationMs,
            positionSec: positionSec,
            artworkUrl: artworkUrl,
            trackUri: trackUri
        )
    }
    
    func playTrack(uri: String) {
        let script = "tell application \"Spotify\" to play track \"\(uri)\""
        _ = executeAppleScript(script)
    }
    
    private func executeAppleScript(_ source: String) -> String? {
        guard let script = NSAppleScript(source: source) else { return nil }
        var error: NSDictionary?
        let result = script.executeAndReturnError(&error)
        if error != nil {
            return nil
        }
        return result.stringValue
    }
}

struct LocalPlaybackState {
    let isPlaying: Bool
    let trackName: String
    let artist: String
    let albumName: String
    let durationMs: Int
    let positionSec: Double
    let artworkUrl: String
    let trackUri: String
}
