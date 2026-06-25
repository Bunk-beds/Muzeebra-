import Foundation
import Network
import CryptoKit
import AppKit

class MuzeebraLogger {
    static let shared = MuzeebraLogger()
    private let logURL: URL
    
    init() {
        if let cachesURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
            logURL = cachesURL.appendingPathComponent("muzeebra.log")
        } else {
            logURL = URL(fileURLWithPath: "/tmp/muzeebra.log")
        }
        // Initialize file
        if !FileManager.default.fileExists(atPath: logURL.path) {
            try? "".write(to: logURL, atomically: true, encoding: .utf8)
        }
        print("Muzeebra Logger initialized at: \(logURL.path)")
    }
    
    func log(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .medium)
        let logLine = "[\(timestamp)] \(message)\n"
        print(logLine, terminator: "")
        
        if let data = logLine.data(using: .utf8) {
            if let fileHandle = try? FileHandle(forWritingTo: logURL) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                fileHandle.closeFile()
            }
        }
    }
}

class SpotifyWebService {
    static let shared = SpotifyWebService()
    
    private let redirectUri = "http://127.0.0.1:5073/callback"
    private let scopes = "user-read-playback-state user-modify-playback-state user-read-currently-playing user-library-read playlist-read-private user-top-read user-read-recently-played streaming user-read-email user-read-private playlist-modify-public playlist-modify-private"
    
    static let defaultClientId = ""
    
    var clientId: String {
        get {
            let saved = UserDefaults.standard.string(forKey: "muzeebra_client_id") ?? ""
            return saved.isEmpty ? Self.defaultClientId : saved
        }
        set { UserDefaults.standard.set(newValue, forKey: "muzeebra_client_id") }
    }
    
    var accessToken: String? {
        get { UserDefaults.standard.string(forKey: "muzeebra_access_token") }
        set { UserDefaults.standard.set(newValue, forKey: "muzeebra_access_token") }
    }
    
    var refreshToken: String? {
        get { UserDefaults.standard.string(forKey: "muzeebra_refresh_token") }
        set { UserDefaults.standard.set(newValue, forKey: "muzeebra_refresh_token") }
    }
    
    var tokenExpiry: Date? {
        get { UserDefaults.standard.object(forKey: "muzeebra_token_expiry") as? Date }
        set { UserDefaults.standard.set(newValue, forKey: "muzeebra_token_expiry") }
    }
    
    var isLoggedIn: Bool {
        return accessToken != nil
    }
    
    // Tracking API usage
    var apiRequestsCount: Int = 0
    
    private var codeVerifier: String?
    private var callbackServer: SpotifyCallbackServer?
    
    func initiateLogin(clientId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        self.clientId = clientId.trimmingCharacters(in: .whitespacesAndNewlines)
        MuzeebraLogger.shared.log("Initiating login flow for Client ID: \(self.clientId)")
        
        // 1. Generate Verifier and Challenge
        let verifier = generateCodeVerifier()
        self.codeVerifier = verifier
        let challenge = generateCodeChallenge(from: verifier)
        MuzeebraLogger.shared.log("Generated PKCE verifier: \(verifier) and challenge: \(challenge)")
        
        // 2. Start Callback Server
        callbackServer?.stop()
        callbackServer = SpotifyCallbackServer()
        callbackServer?.onCodeReceived = { [weak self] code in
            MuzeebraLogger.shared.log("OAuth server received code: \(code.prefix(8))... exchanging for token")
            self?.exchangeCodeForToken(code: code, verifier: verifier, completion: completion)
        }
        callbackServer?.onError = { error in
            MuzeebraLogger.shared.log("OAuth server encountered error: \(error.localizedDescription)")
            completion(.failure(error))
        }
        callbackServer?.start()
        MuzeebraLogger.shared.log("OAuth redirect listener started on port 5073")
        
        // 3. Open Spotify Auth URL in browser
        var authUrlComponents = URLComponents(string: "https://accounts.spotify.com/authorize")!
        authUrlComponents.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: self.clientId),
            URLQueryItem(name: "scope", value: scopes),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "code_challenge", value: challenge),
            URLQueryItem(name: "redirect_uri", value: redirectUri)
        ]
        
        if let authUrl = authUrlComponents.url {
            MuzeebraLogger.shared.log("Opening auth browser URL: \(authUrl.absoluteString)")
            NSWorkspace.shared.open(authUrl)
        } else {
            MuzeebraLogger.shared.log("Error: Failed to create Auth URL components")
            completion(.failure(NSError(domain: "Muzeebra", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid Auth URL"])))
        }
    }
    
    func logout() {
        MuzeebraLogger.shared.log("User triggered logout. Clearing tokens.")
        accessToken = nil
        refreshToken = nil
        tokenExpiry = nil
        callbackServer?.stop()
    }
    
    private func generateCodeVerifier() -> String {
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~"
        return String((0..<64).map { _ in characters.randomElement()! })
    }
    
    private func generateCodeChallenge(from verifier: String) -> String {
        let inputData = Data(verifier.utf8)
        let hashed = SHA256.hash(data: inputData)
        let data = Data(hashed)
        return data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
    
    // Exchange Auth Code for Tokens
    private func exchangeCodeForToken(code: String, verifier: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let tokenUrl = URL(string: "https://accounts.spotify.com/api/token")!
        var request = URLRequest(url: tokenUrl)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let bodyComponents = [
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": redirectUri,
            "client_id": clientId,
            "code_verifier": verifier
        ]
        
        request.httpBody = bodyComponents.map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
            .joined(separator: "&")
            .data(using: .utf8)
        
        MuzeebraLogger.shared.log("Sending token exchange request to /api/token")
        apiRequestsCount += 1
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                MuzeebraLogger.shared.log("Token exchange failed with error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                MuzeebraLogger.shared.log("Token exchange returned empty response data")
                completion(.failure(NSError(domain: "Muzeebra", code: 2, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let access = json["access_token"] as? String,
                       let refresh = json["refresh_token"] as? String,
                       let expiresIn = json["expires_in"] as? Double {
                        
                        self?.accessToken = access
                        self?.refreshToken = refresh
                        self?.tokenExpiry = Date().addingTimeInterval(expiresIn)
                        
                        MuzeebraLogger.shared.log("Token exchange succeeded! Token expires in \(expiresIn) seconds.")
                        completion(.success(()))
                    } else if let errorMsg = json["error_description"] as? String {
                        MuzeebraLogger.shared.log("Token exchange error from Spotify: \(errorMsg)")
                        completion(.failure(NSError(domain: "Muzeebra", code: 3, userInfo: [NSLocalizedDescriptionKey: errorMsg])))
                    } else if let errorObj = json["error"] as? String {
                        MuzeebraLogger.shared.log("Token exchange error from Spotify: \(errorObj)")
                        completion(.failure(NSError(domain: "Muzeebra", code: 3, userInfo: [NSLocalizedDescriptionKey: errorObj])))
                    } else {
                        MuzeebraLogger.shared.log("Token exchange failed with malformed JSON: \(json)")
                        completion(.failure(NSError(domain: "Muzeebra", code: 4, userInfo: [NSLocalizedDescriptionKey: "Malformed response"])))
                    }
                }
            } catch {
                MuzeebraLogger.shared.log("Failed to parse token exchange response: \(error.localizedDescription). Raw response: \(String(data: data, encoding: .utf8) ?? "")")
                completion(.failure(error))
            }
        }.resume()
    }
    
    // Refresh the Token
    func refreshAccessToken(completion: @escaping (Result<String, Error>) -> Void) {
        guard let refresh = refreshToken else {
            MuzeebraLogger.shared.log("Error: No refresh token available to trigger refresh")
            completion(.failure(NSError(domain: "Muzeebra", code: 5, userInfo: [NSLocalizedDescriptionKey: "No refresh token available"])))
            return
        }
        
        let tokenUrl = URL(string: "https://accounts.spotify.com/api/token")!
        var request = URLRequest(url: tokenUrl)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let bodyComponents = [
            "grant_type": "refresh_token",
            "refresh_token": refresh,
            "client_id": clientId
        ]
        
        request.httpBody = bodyComponents.map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
            .joined(separator: "&")
            .data(using: .utf8)
        
        MuzeebraLogger.shared.log("Refreshing access token...")
        apiRequestsCount += 1
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                MuzeebraLogger.shared.log("Token refresh failed with error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                MuzeebraLogger.shared.log("Token refresh returned empty response data")
                completion(.failure(NSError(domain: "Muzeebra", code: 6, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let access = json["access_token"] as? String {
                        self?.accessToken = access
                        if let refreshNew = json["refresh_token"] as? String {
                            self?.refreshToken = refreshNew
                        }
                        if let expiresIn = json["expires_in"] as? Double {
                            self?.tokenExpiry = Date().addingTimeInterval(expiresIn)
                        }
                        MuzeebraLogger.shared.log("Token refreshed successfully!")
                        completion(.success(access))
                    } else if let errorMsg = json["error_description"] as? String {
                        MuzeebraLogger.shared.log("Token refresh error from Spotify: \(errorMsg)")
                        completion(.failure(NSError(domain: "Muzeebra", code: 7, userInfo: [NSLocalizedDescriptionKey: errorMsg])))
                    } else {
                        MuzeebraLogger.shared.log("Token refresh returned malformed JSON: \(json)")
                        completion(.failure(NSError(domain: "Muzeebra", code: 8, userInfo: [NSLocalizedDescriptionKey: "Malformed refresh response"])))
                    }
                }
            } catch {
                MuzeebraLogger.shared.log("Failed to parse token refresh response: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }.resume()
    }
    
    private func getValidToken(completion: @escaping (Result<String, Error>) -> Void) {
        guard let token = accessToken else {
            completion(.failure(NSError(domain: "Muzeebra", code: 9, userInfo: [NSLocalizedDescriptionKey: "Not logged in"])))
            return
        }
        
        if let expiry = tokenExpiry {
            if expiry > Date() {
                completion(.success(token))
            } else {
                MuzeebraLogger.shared.log("Access token expired at \(expiry.description). Triggering refresh.")
                refreshAccessToken(completion: completion)
            }
        } else {
            MuzeebraLogger.shared.log("Access token has no expiry date set. Triggering refresh.")
            refreshAccessToken(completion: completion)
        }
    }
    
    // Perform Web Request
    func performRequest(endpoint: String, method: String = "GET", jsonBody: [String: Any]? = nil, completion: @escaping (Result<Data, Error>) -> Void) {
        getValidToken { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let err):
                MuzeebraLogger.shared.log("Cannot perform API request \(endpoint): \(err.localizedDescription)")
                completion(.failure(err))
            case .success(let token):
                let url = URL(string: "https://api.spotify.com\(endpoint)")!
                var request = URLRequest(url: url)
                request.httpMethod = method
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                
                if let json = jsonBody {
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.httpBody = try? JSONSerialization.data(withJSONObject: json)
                }
                
                self.apiRequestsCount += 1
                URLSession.shared.dataTask(with: request) { data, response, error in
                    if let error = error {
                        MuzeebraLogger.shared.log("API request \(endpoint) failed with error: \(error.localizedDescription)")
                        completion(.failure(error))
                        return
                    }
                    guard let data = data else {
                        MuzeebraLogger.shared.log("API request \(endpoint) returned no data")
                        completion(.failure(NSError(domain: "Muzeebra", code: 10, userInfo: [NSLocalizedDescriptionKey: "No data returned"])))
                        return
                    }
                    
                    // Handle HTTP error codes
                    if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                        if httpResponse.statusCode == 204 {
                            completion(.success(data))
                            return
                        }
                        let errorMsg = String(data: data, encoding: .utf8) ?? "HTTP \(httpResponse.statusCode) Error"
                        MuzeebraLogger.shared.log("API request \(endpoint) returned HTTP \(httpResponse.statusCode). Response: \(errorMsg)")
                        completion(.failure(NSError(domain: "Muzeebra", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMsg])))
                        return
                    }
                    
                    completion(.success(data))
                }.resume()
            }
        }
    }
}

class SpotifyCallbackServer {
    private var listener: NWListener?
    let port: UInt16 = 5073
    var onCodeReceived: ((String) -> Void)?
    var onError: ((Error) -> Void)?

    func start() {
        do {
            let nwPort = NWEndpoint.Port(rawValue: port)!
            listener = try NWListener(using: .tcp, on: nwPort)
            
            listener?.newConnectionHandler = { [weak self] connection in
                self?.handleConnection(connection)
            }
            
            listener?.stateUpdateHandler = { [weak self] state in
                switch state {
                case .failed(let err):
                    self?.onError?(err)
                default:
                    break
                }
            }
            
            listener?.start(queue: .main)
        } catch {
            onError?(error)
        }
    }

    func stop() {
        listener?.cancel()
        listener = nil
    }

    private func handleConnection(_ connection: NWConnection) {
        connection.start(queue: .main)
        
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            guard let self = self else { return }
            if let data = data, !data.isEmpty, let requestStr = String(data: data, encoding: .utf8) {
                MuzeebraLogger.shared.log("OAuth listener caught HTTP request:\n\(requestStr.prefix(200))...")
                
                // Parse the code from request: GET /callback?code=AQ... HTTP/1.1
                if let range = requestStr.range(of: "GET /callback?") {
                    let substring = requestStr[range.upperBound...]
                    if let endOfPathRange = substring.range(of: " ") {
                        let queryStr = String(substring[..<endOfPathRange.lowerBound])
                        let components = queryStr.components(separatedBy: "&")
                        var code: String?
                        for component in components {
                            let pair = component.components(separatedBy: "=")
                            if pair.count == 2, pair[0] == "code" {
                                code = pair[1]
                                break
                            }
                        }
                        if let receivedCode = code {
                            MuzeebraLogger.shared.log("Successfully extracted code from query parameters")
                            self.sendSuccessResponse(on: connection)
                            self.onCodeReceived?(receivedCode)
                            self.stop()
                            return
                        }
                    }
                }
                
                // Default error / invalid path
                MuzeebraLogger.shared.log("Request did not contain a valid code in /callback")
                self.sendErrorResponse(on: connection)
            }
            
            if isComplete || error != nil {
                connection.cancel()
            }
        }
    }

    private func sendSuccessResponse(on connection: NWConnection) {
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <title>Muzeebra Login Successful</title>
            <style>
                body {
                    background: linear-gradient(135deg, #0d0d11 0%, #151525 100%);
                    color: #ffffff;
                    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    height: 100vh;
                    margin: 0;
                }
                .card {
                    background: rgba(255, 255, 255, 0.05);
                    backdrop-filter: blur(20px);
                    border: 1px solid rgba(255, 255, 255, 0.1);
                    padding: 40px;
                    border-radius: 20px;
                    text-align: center;
                    box-shadow: 0 10px 30px rgba(0, 0, 0, 0.5);
                    max-width: 400px;
                }
                h1 { color: #1DB954; margin-top: 0; margin-bottom: 15px; font-weight: 700; }
                p { color: #b3b3b3; line-height: 1.5; margin-bottom: 0; }
            </style>
        </head>
        <body>
            <div class="card">
                <h1>Muzeebra Connected!</h1>
                <p>Your Spotify account has been successfully linked. You can close this window now and return to the Muzeebra menubar app.</p>
            </div>
        </body>
        </html>
        """
        
        let response = """
        HTTP/1.1 200 OK
        Content-Type: text/html; charset=utf-8
        Content-Length: \(html.utf8.count)
        Connection: close
        
        \(html)
        """
        
        connection.send(content: response.data(using: .utf8), completion: .contentProcessed({ _ in
            connection.cancel()
        }))
    }

    private func sendErrorResponse(on connection: NWConnection) {
        let html = "<html><body><h1>Invalid Callback</h1></body></html>"
        let response = """
        HTTP/1.1 400 Bad Request
        Content-Type: text/html; charset=utf-8
        Content-Length: \(html.utf8.count)
        Connection: close
        
        \(html)
        """
        connection.send(content: response.data(using: .utf8), completion: .contentProcessed({ _ in
            connection.cancel()
        }))
    }
}
