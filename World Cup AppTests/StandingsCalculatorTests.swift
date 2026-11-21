import XCTest
@testable import World_Cup_App

final class StandingsCalculatorTests: XCTestCase {

    private func match(
        _ home: String, _ away: String, _ homeGoals: Int, _ awayGoals: Int,
        stage: Stage = .group("Group A")
    ) -> Match {
        Match(
            id: "\(home)-\(away)-\(stage)",
            stage: stage,
            kickoff: Date(timeIntervalSince1970: 0),
            homeTeam: home,
            awayTeam: away,
            score: Score(
                fullTime: ScoreLine(home: homeGoals, away: awayGoals),
                halfTime: ScoreLine(home: 0, away: 0)
            ),
            homeGoals: [],
            awayGoals: [],
            venue: "Test"
        )
    }

    func testWinDrawLossAreScoredAndRecorded() throws {
        let tables = StandingsCalculator.tables(from: [
            match("A", "B", 2, 0),
            match("A", "C", 1, 1),
        ])

        let a = try XCTUnwrap(tables.first?.standings.first { $0.team == "A" })
        XCTAssertEqual(a.played, 2)
        XCTAssertEqual(a.won, 1)
        XCTAssertEqual(a.drawn, 1)
        XCTAssertEqual(a.points, 4)
        XCTAssertEqual(a.goalsFor, 3)
        XCTAssertEqual(a.goalsAgainst, 1)
        XCTAssertEqual(a.goalDifference, 2)

        let b = try XCTUnwrap(tables.first?.standings.first { $0.team == "B" })
        XCTAssertEqual(b.lost, 1)
        XCTAssertEqual(b.points, 0)
    }

    func testGoalDifferenceBreaksPointsTie() {
        // A and B both finish on 3 points. B has the better goal difference,
        // even though A comes first alphabetically.
        let tables = StandingsCalculator.tables(from: [
            match("A", "C", 1, 0),
            match("B", "D", 3, 0),
        ])
        let order = tables[0].standings.map(\.team)

        XCTAssertLessThan(order.firstIndex(of: "B")!, order.firstIndex(of: "A")!)
    }

    func testGoalsScoredBreaksTieOnPointsAndGoalDifference() {
        // P and Q both: 3 points, goal difference +1. Q scored more.
        let tables = StandingsCalculator.tables(from: [
            match("P", "R", 1, 0),
            match("Q", "S", 3, 2),
        ])
        let order = tables[0].standings.map(\.team)

        XCTAssertLessThan(order.firstIndex(of: "Q")!, order.firstIndex(of: "P")!)
    }

    func testNameIsLastResortSoOrderIsDeterministic() {
        let tables = StandingsCalculator.tables(from: [
            match("B", "A", 1, 1),
        ])

        XCTAssertEqual(tables[0].standings.map(\.team), ["A", "B"])
    }

    func testKnockoutMatchesAreIgnored() {
        let tables = StandingsCalculator.tables(from: [
            match("A", "B", 1, 0),
            match("A", "B", 5, 0, stage: .roundOf16),
        ])

        XCTAssertEqual(tables.count, 1)
        XCTAssertEqual(tables[0].standings.first { $0.team == "A" }?.goalsFor, 1)
    }

    func testGroupsAreSeparateAndSortedByName() {
        let tables = StandingsCalculator.tables(from: [
            match("C", "D", 1, 0, stage: .group("Group B")),
            match("A", "B", 1, 0, stage: .group("Group A")),
        ])

        XCTAssertEqual(tables.map(\.name), ["Group A", "Group B"])
    }
}
