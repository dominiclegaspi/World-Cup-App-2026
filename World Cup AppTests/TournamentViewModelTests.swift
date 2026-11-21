import XCTest
@testable import World_Cup_App

@MainActor
final class TournamentViewModelTests: XCTestCase {

    private struct StubService: MatchesProviding {
        let result: Result<[Match], Error>
        func fetchMatches() async throws -> [Match] { try result.get() }
    }

    private func match(_ id: String, kickoff: String, stage: Stage = .group("Group A")) -> Match {
        Match(
            id: id,
            stage: stage,
            kickoff: ISO8601DateFormatter().date(from: kickoff)!,
            homeTeam: "\(id)-home",
            awayTeam: "\(id)-away",
            score: Score(fullTime: ScoreLine(home: 1, away: 0), halfTime: ScoreLine(home: 0, away: 0)),
            homeGoals: [],
            awayGoals: [],
            venue: "Test"
        )
    }

    private var utc: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    func testStartsIdle() {
        let viewModel = TournamentViewModel(service: StubService(result: .success([])), calendar: utc)

        XCTAssertEqual(viewModel.state, .idle)
    }

    func testLoadPublishesMatchesTablesAndDays() async {
        let matches = [
            match("m1", kickoff: "2026-06-11T19:00:00Z"),
            match("m2", kickoff: "2026-06-12T01:00:00Z"),
        ]
        let viewModel = TournamentViewModel(service: StubService(result: .success(matches)), calendar: utc)

        await viewModel.load()

        XCTAssertEqual(viewModel.state, .loaded(matches))
        XCTAssertEqual(viewModel.groupTables.count, 1)
        XCTAssertEqual(viewModel.days.count, 2)
    }

    func testLoadFailureShowsReadableMessage() async {
        let error = MatchesError.badStatus(500)
        let viewModel = TournamentViewModel(service: StubService(result: .failure(error)), calendar: utc)

        await viewModel.load()

        XCTAssertEqual(viewModel.state, .failed(error.localizedDescription))
    }

    func testScheduleGroupsByDayAndOrdersByKickoff() {
        let matches = [
            match("late", kickoff: "2026-06-11T23:00:00Z"),
            match("early", kickoff: "2026-06-11T19:00:00Z"),
            match("nextDay", kickoff: "2026-06-12T01:00:00Z"),
        ]

        let days = ScheduleBuilder.days(from: matches, calendar: utc)

        XCTAssertEqual(days.count, 2)
        XCTAssertEqual(days[0].matches.map(\.id), ["early", "late"])
        XCTAssertEqual(days[1].matches.map(\.id), ["nextDay"])
    }

    func testScheduleDayDependsOnTimeZone() {
        // 01:00 UTC on the 12th is still the evening of the 11th in Los Angeles.
        var losAngeles = Calendar(identifier: .gregorian)
        losAngeles.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        let matches = [
            match("a", kickoff: "2026-06-11T19:00:00Z"),
            match("b", kickoff: "2026-06-12T01:00:00Z"),
        ]

        XCTAssertEqual(ScheduleBuilder.days(from: matches, calendar: utc).count, 2)
        XCTAssertEqual(ScheduleBuilder.days(from: matches, calendar: losAngeles).count, 1)
    }
}
