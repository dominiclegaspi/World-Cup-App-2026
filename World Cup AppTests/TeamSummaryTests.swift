import SwiftData
import XCTest
@testable import World_Cup_App

final class TeamSummaryTests: XCTestCase {

    private func match(
        _ id: String, _ home: String, _ away: String,
        ft: (Int, Int), pens: (Int, Int)? = nil, hour: Int = 0,
        homeGoals: [Goal] = [], awayGoals: [Goal] = [],
        stage: Stage = .group("Group A")
    ) -> Match {
        Match(
            id: id,
            stage: stage,
            kickoff: Date(timeIntervalSince1970: TimeInterval(hour * 3600)),
            homeTeam: home,
            awayTeam: away,
            score: Score(
                fullTime: ScoreLine(home: ft.0, away: ft.1),
                halfTime: ScoreLine(home: 0, away: 0),
                penalties: pens.map { ScoreLine(home: $0.0, away: $0.1) }
            ),
            homeGoals: homeGoals,
            awayGoals: awayGoals,
            venue: "Test"
        )
    }

    func testOutcomeFromEachSidesPointOfView() {
        let score = Score(fullTime: ScoreLine(home: 2, away: 1), halfTime: ScoreLine(home: 0, away: 0))

        XCTAssertEqual(score.outcome(asHome: true), .win)
        XCTAssertEqual(score.outcome(asHome: false), .loss)
    }

    func testLevelMatchIsDecidedByPenaltiesWhenThereWereAny() {
        let shootout = Score(
            fullTime: ScoreLine(home: 1, away: 1), halfTime: ScoreLine(home: 0, away: 0),
            penalties: ScoreLine(home: 3, away: 4)
        )
        let draw = Score(fullTime: ScoreLine(home: 1, away: 1), halfTime: ScoreLine(home: 0, away: 0))

        XCTAssertEqual(shootout.outcome(asHome: true), .loss)
        XCTAssertEqual(shootout.outcome(asHome: false), .win)
        XCTAssertEqual(draw.outcome(asHome: true), .draw)
    }

    func testResultsAreInKickoffOrderFromTheTeamsPointOfView() {
        let matches = [
            match("later", "B", "A", ft: (0, 2), hour: 10),
            match("earlier", "A", "C", ft: (1, 1), hour: 1),
            match("other", "B", "C", ft: (3, 0), hour: 5),
        ]

        let summary = TeamSummaryBuilder.summary(for: "A", in: matches)

        XCTAssertEqual(summary.results.map(\.id), ["earlier", "later"])
        XCTAssertEqual(summary.results[1].opponent, "B")
        XCTAssertEqual(summary.results[1].goalsFor, 2)
        XCTAssertEqual(summary.results[1].goalsAgainst, 0)
        XCTAssertEqual(summary.results[1].outcome, .win)
    }

    func testOwnGoalsDoNotCountForTheScorersTeam() {
        // The own goal sits in A's list (A benefited) under a player from B.
        let matches = [
            match(
                "m1", "A", "B", ft: (2, 0),
                homeGoals: [
                    Goal(scorer: "Alvarez", minute: "10"),
                    Goal(scorer: "Unlucky from B", minute: "50", isOwnGoal: true),
                ]
            ),
            match("m2", "C", "A", ft: (0, 1), awayGoals: [Goal(scorer: "Alvarez", minute: "70")]),
        ]

        let a = TeamSummaryBuilder.summary(for: "A", in: matches)
        let b = TeamSummaryBuilder.summary(for: "B", in: matches)

        XCTAssertEqual(a.scorers, [TeamSummary.Scorer(name: "Alvarez", goals: 2)])
        XCTAssertTrue(b.scorers.isEmpty)
    }

    func testGroupAndRankComeFromTheTable() {
        let matches = [
            match("m1", "A", "B", ft: (1, 0)),
            match("m2", "C", "D", ft: (0, 0)),
        ]

        let summary = TeamSummaryBuilder.summary(for: "B", in: matches)

        XCTAssertEqual(summary.groupName, "Group A")
        XCTAssertEqual(summary.groupRank, 4)
        XCTAssertEqual(summary.standing?.points, 0)
    }

    func testUnknownTeamHasEmptySummary() {
        let summary = TeamSummaryBuilder.summary(for: "Nobody", in: [match("m1", "A", "B", ft: (1, 0))])

        XCTAssertTrue(summary.results.isEmpty)
        XCTAssertNil(summary.groupName)
    }
}

@MainActor
final class FavoritesStoreTests: XCTestCase {

    /// The container must outlive the store: a context whose container has been
    /// deallocated crashes on first use. XCTest makes a fresh instance for each
    /// test, so every test gets its own empty in-memory store.
    private lazy var container: ModelContainer = {
        // swiftlint:disable:next force_try
        try! ModelContainer(
            for: FavoriteTeam.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }()

    private func makeStore() -> FavoritesStore {
        FavoritesStore(context: container.mainContext)
    }

    func testToggleAddsThenRemoves() throws {
        let store = makeStore()

        XCTAssertFalse(store.isFavorite("Spain"))
        store.toggle("Spain")
        XCTAssertTrue(store.isFavorite("Spain"))
        store.toggle("Spain")
        XCTAssertFalse(store.isFavorite("Spain"))
    }

    func testFavoritesAreIndependentPerTeam() throws {
        let store = makeStore()

        store.toggle("Spain")

        XCTAssertTrue(store.isFavorite("Spain"))
        XCTAssertFalse(store.isFavorite("Brazil"))
    }
}
