import XCTest
@testable import World_Cup_App

final class PlayerSummaryTests: XCTestCase {

    private func match(
        _ id: String, _ home: String, _ away: String, hour: Int,
        homeGoals: [Goal] = [], awayGoals: [Goal] = []
    ) -> Match {
        Match(
            id: id,
            stage: .group("Group A"),
            kickoff: Date(timeIntervalSince1970: TimeInterval(hour * 3600)),
            homeTeam: home,
            awayTeam: away,
            score: Score(
                fullTime: ScoreLine(home: homeGoals.count, away: awayGoals.count),
                halfTime: ScoreLine(home: 0, away: 0)
            ),
            homeGoals: homeGoals,
            awayGoals: awayGoals,
            venue: "Test"
        )
    }

    func testCollectsEveryGoalInKickoffOrder() {
        let later = match("b", "Spain", "Japan", hour: 5, homeGoals: [Goal(scorer: "Pedri", minute: "10")])
        let earlier = match(
            "a", "Italy", "Spain", hour: 1,
            awayGoals: [Goal(scorer: "Pedri", minute: "30"), Goal(scorer: "Pedri", minute: "88", isPenalty: true)]
        )

        let summary = PlayerSummaryBuilder.summary(for: "Pedri", team: "Spain", in: [later, earlier])

        XCTAssertEqual(summary.goals.map(\.minute), ["30", "88", "10"])
        XCTAssertEqual(summary.goals.map(\.opponent), ["Italy", "Italy", "Japan"])
        XCTAssertEqual(summary.penaltyCount, 1)
        XCTAssertEqual(summary.matchesScoredIn, 2)
    }

    func testOwnGoalsDoNotCountForTheUnluckyPlayer() {
        // Spain's goal list holds an own goal by a Japanese defender.
        let game = match(
            "a", "Spain", "Japan", hour: 1,
            homeGoals: [Goal(scorer: "Tomiyasu", minute: "20", isOwnGoal: true)]
        )

        let summary = PlayerSummaryBuilder.summary(for: "Tomiyasu", team: "Japan", in: [game])

        XCTAssertTrue(summary.goals.isEmpty)
    }

    func testSameNameOnAnotherTeamIsNotMixedIn() {
        let game = match(
            "a", "Brazil", "Portugal", hour: 1,
            homeGoals: [Goal(scorer: "Silva", minute: "5")],
            awayGoals: [Goal(scorer: "Silva", minute: "50")]
        )

        let summary = PlayerSummaryBuilder.summary(for: "Silva", team: "Portugal", in: [game])

        XCTAssertEqual(summary.goals.map(\.minute), ["50"])
    }

    func testHighlightsLinkEncodesPlayerAndTeam() throws {
        let url = try XCTUnwrap(HighlightsLink.url(player: "Kylian Mbappé", team: "France"))
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))

        XCTAssertEqual(components.host, "www.youtube.com")
        let query = components.queryItems?.first { $0.name == "search_query" }?.value
        XCTAssertEqual(query, "Kylian Mbappé France World Cup 2026 highlights")
    }
}
