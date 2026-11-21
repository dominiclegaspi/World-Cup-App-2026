import XCTest
@testable import World_Cup_App

final class MatchesServiceTests: XCTestCase {

    private let feed = """
    {"name": "World Cup 2026", "matches": [
      {"round": "Matchday 1", "date": "2026-06-11", "time": "13:00 UTC-6",
       "team1": "Mexico", "team2": "South Africa",
       "score": {"ft": [2, 0], "ht": [1, 0]},
       "group": "Group A", "ground": "Mexico City"}
    ]}
    """

    private struct StubLoader: DataLoading {
        let result: Result<(Data, Int), Error>

        func data(from url: URL) async throws -> (Data, URLResponse) {
            let (data, status) = try result.get()
            let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil)!
            return (data, response)
        }
    }

    private final class MemoryCache: DataCache {
        var stored: Data?
        func load() -> Data? { stored }
        func save(_ data: Data) { stored = data }
    }

    private func service(_ result: Result<(Data, Int), Error>, cache: MemoryCache?) -> RemoteMatchesService {
        RemoteMatchesService(
            url: URL(string: "https://example.com/feed.json")!,
            loader: StubLoader(result: result),
            cache: cache
        )
    }

    func testSuccessReturnsMatchesAndFillsCache() async throws {
        let cache = MemoryCache()
        let sut = service(.success((Data(feed.utf8), 200)), cache: cache)

        let matches = try await sut.fetchMatches()

        XCTAssertEqual(matches.count, 1)
        XCTAssertEqual(matches[0].homeTeam, "Mexico")
        XCTAssertNotNil(cache.stored)
    }

    func testNetworkFailureFallsBackToCache() async throws {
        let cache = MemoryCache()
        cache.stored = Data(feed.utf8)
        let sut = service(.failure(URLError(.notConnectedToInternet)), cache: cache)

        let matches = try await sut.fetchMatches()

        XCTAssertEqual(matches.count, 1)
    }

    func testNetworkFailureWithEmptyCacheThrowsNetworkError() async {
        let sut = service(.failure(URLError(.notConnectedToInternet)), cache: MemoryCache())

        do {
            _ = try await sut.fetchMatches()
            XCTFail("Expected an error")
        } catch {
            guard case .network? = error as? MatchesError else {
                return XCTFail("Expected .network, got \(error)")
            }
        }
    }

    func testServerErrorThrowsBadStatus() async {
        let sut = service(.success((Data(), 500)), cache: MemoryCache())

        do {
            _ = try await sut.fetchMatches()
            XCTFail("Expected an error")
        } catch {
            guard case .badStatus(500)? = error as? MatchesError else {
                return XCTFail("Expected .badStatus(500), got \(error)")
            }
        }
    }

    func testMalformedDataIsNotCached() async {
        let cache = MemoryCache()
        let sut = service(.success((Data("not json".utf8), 200)), cache: cache)

        do {
            _ = try await sut.fetchMatches()
            XCTFail("Expected an error")
        } catch {
            guard case .decoding? = error as? MatchesError else {
                return XCTFail("Expected .decoding, got \(error)")
            }
        }
        XCTAssertNil(cache.stored)
    }
}
