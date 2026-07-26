import Foundation
import CryptoKit

/// Danmaku (bullet comment) from dandanplay.
public struct DanmakuComment: Identifiable, Sendable {
    public let id: Int64
    /// Seconds from the start of the episode.
    public let time: Double
    /// 1 = scroll, 4 = bottom, 5 = top (dandanplay convention).
    public let mode: Int
    /// 0xRRGGBB
    public let color: UInt32
    public let text: String

    public init(id: Int64, time: Double, mode: Int, color: UInt32, text: String) {
        self.id = id
        self.time = time
        self.mode = mode
        self.color = color
        self.text = text
    }

    public var uiColorComponents: (r: Double, g: Double, b: Double) {
        (
            Double((color >> 16) & 0xFF) / 255.0,
            Double((color >> 8) & 0xFF) / 255.0,
            Double(color & 0xFF) / 255.0
        )
    }
}

private struct DDPEpisodeSearch: Decodable {
    struct Anime: Decodable {
        struct Episode: Decodable {
            let episodeId: Int
            let episodeTitle: String?
        }
        let animeId: Int
        let animeTitle: String?
        let episodes: [Episode]?
    }
    let animes: [Anime]?
    let success: Bool?
    let errorMessage: String?
}

private struct DDPCommentResponse: Decodable {
    struct Comment: Decodable {
        let cid: Int64
        /// "time,mode,color,uid"
        let p: String
        let m: String
    }
    let comments: [Comment]?
    let count: Int?
}

private struct DDPMatchResponse: Decodable {
    struct Match: Decodable {
        let episodeId: Int
        let animeTitle: String?
        let episodeTitle: String?
    }
    let isMatched: Bool?
    let matches: [Match]?
}

public enum DanmakuService {
    /// Endpoint + credentials. Nothing is baked into this library: the host
    /// application must pass in whatever the END USER configured.
    public struct Configuration: Sendable {
        /// Base URL of a dandanplay-compatible API, e.g.
        /// `https://api.dandanplay.net`. Trailing slash optional.
        public var server: String
        /// Credentials the end user registered themselves.
        public var appId: String
        public var appSecret: String

        public init(server: String, appId: String, appSecret: String) {
            self.server = server
            self.appId = appId
            self.appSecret = appSecret
        }
    }

    private static let lock = NSLock()
    nonisolated(unsafe) private static var _config: Configuration?

    /// Supply endpoint and credentials before use. Call again to change them.
    public static func configure(_ config: Configuration) {
        lock.lock()
        _config = config
        lock.unlock()
    }

    public static func configure(server: String, appId: String, appSecret: String) {
        configure(Configuration(server: server, appId: appId, appSecret: appSecret))
    }

    private static var config: Configuration? {
        lock.lock()
        defer { lock.unlock() }
        return _config
    }

    /// True once a server and a non-empty credential pair are set. When false
    /// the library performs no network requests at all.
    public static var isConfigured: Bool {
        guard let c = config else { return false }
        return !c.server.isEmpty && !c.appId.isEmpty && !c.appSecret.isEmpty
    }

    private static var server: String {
        let base = (config?.server ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return base.hasSuffix("/") ? String(base.dropLast()) : base
    }
    private static var appId: String { config?.appId ?? "" }
    private static var appSecret: String { config?.appSecret ?? "" }

    /// X-Signature = Base64(SHA256(AppId + Timestamp + Path + AppSecret))
    private static func signedRequest(path: String, query: [URLQueryItem] = []) -> URLRequest? {
        guard isConfigured, var comp = URLComponents(string: server + path) else { return nil }
        if !query.isEmpty { comp.queryItems = query }
        guard let url = comp.url else { return nil }

        let ts = String(Int(Date().timeIntervalSince1970))
        let raw = appId + ts + path + appSecret
        let digest = SHA256.hash(data: Data(raw.utf8))
        let sig = Data(digest).base64EncodedString()

        var req = URLRequest(url: url)
        req.timeoutInterval = 20
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue(appId, forHTTPHeaderField: "X-AppId")
        req.setValue(ts, forHTTPHeaderField: "X-Timestamp")
        req.setValue(sig, forHTTPHeaderField: "X-Signature")
        return req
    }

    private static func fetch<T: Decodable>(_ type: T.Type, path: String,
                                            query: [URLQueryItem] = []) async throws -> T {
        guard let req = signedRequest(path: path, query: query) else {
            throw NSError(domain: "Danmaku", code: 401,
                          userInfo: [NSLocalizedDescriptionKey:
                                      "DanmakuService is not configured (call configure(...))"])
        }
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else {
            let code = (resp as? HTTPURLResponse)?.statusCode ?? -1
            throw NSError(domain: "Danmaku", code: code,
                          userInfo: [NSLocalizedDescriptionKey: "Danmaku API returned \(code)"])
        }
        return try JSONDecoder().decode(type, from: data)
    }

    /// Find an episodeId by title (and optional episode number).
    public static func searchEpisodeId(title: String, episode: Int?) async throws -> Int? {
        var q = [URLQueryItem(name: "anime", value: title)]
        if let e = episode { q.append(URLQueryItem(name: "episode", value: String(e))) }
        let r = try await fetch(DDPEpisodeSearch.self, path: "/api/v2/search/episodes", query: q)
        guard let animes = r.animes, let first = animes.first else { return nil }
        return first.episodes?.first?.episodeId
    }

    /// Load comments for an episodeId.
    public static func comments(episodeId: Int, withRelated: Bool = true) async throws -> [DanmakuComment] {
        let r = try await fetch(
            DDPCommentResponse.self,
            path: "/api/v2/comment/\(episodeId)",
            query: [
                URLQueryItem(name: "withRelated", value: withRelated ? "true" : "false"),
                URLQueryItem(name: "chConvert", value: "1")
            ]
        )
        return (r.comments ?? []).compactMap { c in
            // p = "time,mode,color,uid"
            let f = c.p.split(separator: ",").map(String.init)
            guard f.count >= 3,
                  let t = Double(f[0]),
                  let mode = Int(f[1]),
                  let color = UInt32(f[2]) else { return nil }
            return DanmakuComment(id: c.cid, time: t, mode: mode, color: color, text: c.m)
        }
        .sorted { $0.time < $1.time }
    }

    /// Convenience: resolve by title then fetch.
    public static func load(title: String, episode: Int?) async throws -> [DanmakuComment] {
        guard let eid = try await searchEpisodeId(title: title, episode: episode) else { return [] }
        return try await comments(episodeId: eid)
    }
}
