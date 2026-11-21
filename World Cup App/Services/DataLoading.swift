import Foundation

/// The one network operation the app needs. Depending on this instead of
/// `URLSession` directly lets tests supply canned responses.
protocol DataLoading {
    func data(from url: URL) async throws -> (Data, URLResponse)
}

struct URLSessionLoader: DataLoading {
    var session: URLSession = .shared

    func data(from url: URL) async throws -> (Data, URLResponse) {
        try await session.data(from: url)
    }
}

/// Keeps the last good download so the app still works offline.
protocol DataCache {
    func load() -> Data?
    func save(_ data: Data)
}

struct DiskDataCache: DataCache {
    let fileURL: URL

    static func caches(named fileName: String) -> DiskDataCache {
        let directory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return DiskDataCache(fileURL: directory.appendingPathComponent(fileName))
    }

    func load() -> Data? {
        try? Data(contentsOf: fileURL)
    }

    /// Best effort: failing to write the cache must never fail the request.
    func save(_ data: Data) {
        try? data.write(to: fileURL, options: .atomic)
    }
}
