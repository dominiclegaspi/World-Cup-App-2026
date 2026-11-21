import XCTest
@testable import World_Cup_App

final class MatchDecodingTests: XCTestCase {

    private func decode(_ json: String) throws -> Match {
        try JSONDecoder().decode(Match.self, from: Data(json.utf8))
    }

    private func instant(_ iso: String) -> Date {
        ISO8601DateFormatter().date(from: iso)!
    }

    func testDecodesGroupMatch() throws {
        let match = try decode("""
        {"round": "Matchday 1", "date": "2026-06-11", "time": "13:00 UTC-6",
         "team1": "Mexico", "team2": "South Africa",
         "score": {"ft": [2, 0], "ht": [1, 0]},
         "goals1": [{"name": "Julián Quiñones", "minute": "9"},
                    {"name": "Raúl Jiménez", "minute": "67"}],
         "goals2": [], "group": "Group A", "ground": "Mexico City"}
        """)

        XCTAssertEqual(match.stage, .group("Group A"))
        XCTAssertEqual(match.homeTeam, "Mexico")
        XCTAssertEqual(match.score.fullTime, ScoreLine(home: 2, away: 0))
        XCTAssertNil(match.score.extraTime)
        XCTAssertEqual(match.homeGoals.count, 2)
        XCTAssertTrue(match.awayGoals.isEmpty)
        // 13:00 at UTC-6 is 19:00 UTC.
        XCTAssertEqual(match.kickoff, instant("2026-06-11T19:00:00Z"))
        XCTAssertEqual(match.id, "2026-06-11-Mexico-South Africa")
    }

    func testDecodesKnockoutMatchDecidedOnPenalties() throws {
        let match = try decode("""
        {"round": "Round of 32", "num": 74, "date": "2026-06-29", "time": "16:30 UTC-4",
         "team1": "Germany", "team2": "Paraguay",
         "score": {"p": [3, 4], "et": [1, 1], "ft": [1, 1], "ht": [0, 1]},
         "goals1": [{"name": "Kai Havertz", "minute": "54"}],
         "goals2": [{"name": "Julio Enciso", "minute": "42"}],
         "ground": "Boston (Foxborough)"}
        """)

        XCTAssertEqual(match.stage, .roundOf32)
        XCTAssertEqual(match.id, "match-74")
        XCTAssertEqual(match.score.extraTime, ScoreLine(home: 1, away: 1))
        XCTAssertEqual(match.score.penalties, ScoreLine(home: 3, away: 4))
        XCTAssertEqual(match.kickoff, instant("2026-06-29T20:30:00Z"))
    }

    func testMissingGoalListsDecodeAsEmpty() throws {
        let match = try decode("""
        {"round": "Matchday 15", "date": "2026-06-25", "time": "19:00 UTC-7",
         "team1": "Paraguay", "team2": "Australia",
         "score": {"ft": [0, 0], "ht": [0, 0]},
         "group": "Group D", "ground": "San Francisco Bay Area (Santa Clara)"}
        """)

        XCTAssertTrue(match.homeGoals.isEmpty)
        XCTAssertTrue(match.awayGoals.isEmpty)
    }

    func testGoalFlagsDefaultToFalseAndDecodeWhenPresent() throws {
        let data = Data("""
        [{"name": "A", "minute": "10"},
         {"name": "B", "minute": "83", "penalty": true},
         {"name": "C", "minute": "90+6", "owngoal": true}]
        """.utf8)
        let goals = try JSONDecoder().decode([Goal].self, from: data)

        XCTAssertFalse(goals[0].isPenalty || goals[0].isOwnGoal)
        XCTAssertTrue(goals[1].isPenalty)
        XCTAssertTrue(goals[2].isOwnGoal)
        XCTAssertEqual(goals[2].minute, "90+6")
    }

    func testUnknownRoundThrows() {
        XCTAssertThrowsError(try decode("""
        {"round": "Play-off", "date": "2026-06-11", "time": "13:00 UTC-6",
         "team1": "A", "team2": "B", "score": {"ft": [0, 0], "ht": [0, 0]}, "ground": "X"}
        """))
    }

    func testMalformedScorePairThrows() {
        XCTAssertThrowsError(try JSONDecoder().decode(ScoreLine.self, from: Data("[1, 2, 3]".utf8)))
    }

    func testKickoffParserHandlesHalfHourOffsetAndBadInput() {
        XCTAssertEqual(
            KickoffParser.parse(date: "2026-06-11", time: "13:00 UTC+5:30"),
            instant("2026-06-11T07:30:00Z")
        )
        XCTAssertNil(KickoffParser.parse(date: "2026-06-11", time: "13:00"))
        XCTAssertNil(KickoffParser.parse(date: "not-a-date", time: "13:00 UTC-6"))
    }
}
