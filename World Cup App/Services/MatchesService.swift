import Foundation

/// Source of tournament matches. View models depend on this protocol, so they
/// can be tested without touching the network.
protocol MatchesProviding {
    func fetchMatches() async throws -> [Match]
}

enum MatchesError: LocalizedError {
    case network(Error)
    case badStatus(Int)
    case decoding(Error)

    var errorDescription: String? {
        switch self {
        case .network:
            return "Couldn't reach the server. Check your connection."
        case .badStatus(let code):
            return "The server returned an error (\(code))."
        case .decoding:
            return "The match data was in an unexpected format."
        }
    }
}

/// Downloads the 2026 World Cup feed from the public openfootball dataset.
/// Falls back to the last good download if the fresh request fails.
struct RemoteMatchesService: MatchesProviding {
    static let defaultURL = URL(
        string: "https://raw.githubusercontent.com/openfootball/worldcup.json/master/2026/worldcup.json"
    )!

    let url: URL
    let loader: DataLoading
    let cache: DataCache?

    init(
        url: URL = RemoteMatchesService.defaultURL,
        loader: DataLoading = URLSessionLoader(),
        cache: DataCache? = DiskDataCache.caches(named: "matches.json")
    ) {
        self.url = url
        self.loader = loader
        self.cache = cache
    }

    func fetchMatches() async throws -> [Match] {
        do {
            let data = try await download()
            let matches = try decode(data)
            // Only data that decoded successfully is worth keeping.
            cache?.save(data)
            return matches
        } catch {
            // A cancelled task is not a failure to paper over with old data.
            try Task.checkCancellation()
            if let cached = cache?.load(), let matches = try? decode(cached) {
                return matches
            }
            throw error
        }
    }

    private func download() async throws -> Data {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await loader.data(from: url)
        } catch {
            throw MatchesError.network(error)
        }
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw MatchesError.badStatus(http.statusCode)
        }
        return data
    }

    private func decode(_ data: Data) throws -> [Match] {
        do {
            return try JSONDecoder().decode(Feed.self, from: data).matches
        } catch {
            throw MatchesError.decoding(error)
        }
    }

    /// The feed wraps the match list in an object with the tournament name.
    private struct Feed: Decodable {
        let matches: [Match]
    }
}
