import XCTest
@testable import World_Cup_App

final class DisplayTests: XCTestCase {

    private func score(ft: (Int, Int), et: (Int, Int)? = nil, pens: (Int, Int)? = nil) -> Score {
        Score(
            fullTime: ScoreLine(home: ft.0, away: ft.1),
            halfTime: ScoreLine(home: 0, away: 0),
            extraTime: et.map { ScoreLine(home: $0.0, away: $0.1) },
            penalties: pens.map { ScoreLine(home: $0.0, away: $0.1) }
        )
    }

    func testScoreSummaryForNormalTime() {
        XCTAssertEqual(score(ft: (2, 0)).summary, "2–0")
    }

    func testScoreSummaryUsesExtraTimeScore() {
        XCTAssertEqual(score(ft: (0, 0), et: (1, 0)).summary, "1–0 aet")
    }

    func testScoreSummaryShowsPenalties() {
        XCTAssertEqual(score(ft: (1, 1), et: (1, 1), pens: (3, 4)).summary, "1–1 (3–4 pens)")
    }

    func testStageTitles() {
        XCTAssertEqual(Stage.group("Group C").title, "Group C")
        XCTAssertEqual(Stage.quarterFinal.title, "Quarter-final")
        XCTAssertEqual(Stage.thirdPlace.title, "Third place")
    }

    func testCountryFlagsUseRegionalIndicators() {
        XCTAssertEqual(TeamFlag.emoji(for: "Mexico"), "🇲🇽")
        XCTAssertEqual(TeamFlag.emoji(for: "USA"), "🇺🇸")
    }

    func testSubdivisionFlagsForEnglandAndScotland() {
        for team in ["England", "Scotland"] {
            let scalars = Array(TeamFlag.emoji(for: team).unicodeScalars)
            XCTAssertEqual(scalars.count, 7, team)
            XCTAssertEqual(scalars.first?.value, 0x1F3F4, team)
            XCTAssertEqual(scalars.last?.value, 0xE007F, team)
        }
        XCTAssertNotEqual(TeamFlag.emoji(for: "England"), TeamFlag.emoji(for: "Scotland"))
    }

    func testUnknownTeamGetsFallbackFlag() {
        XCTAssertEqual(TeamFlag.emoji(for: "Atlantis"), TeamFlag.fallback)
    }

    func testEveryTeamInThe2026FieldHasAFlag() {
        let field = [
            "Algeria", "Argentina", "Australia", "Austria", "Belgium", "Bosnia & Herzegovina",
            "Brazil", "Canada", "Cape Verde", "Colombia", "Croatia", "Curaçao", "Czech Republic",
            "DR Congo", "Ecuador", "Egypt", "England", "France", "Germany", "Ghana", "Haiti",
            "Iran", "Iraq", "Ivory Coast", "Japan", "Jordan", "Mexico", "Morocco", "Netherlands",
            "New Zealand", "Norway", "Panama", "Paraguay", "Portugal", "Qatar", "Saudi Arabia",
            "Scotland", "Senegal", "South Africa", "South Korea", "Spain", "Sweden", "Switzerland",
            "Tunisia", "Turkey", "USA", "Uruguay", "Uzbekistan",
        ]
        XCTAssertEqual(field.count, 48)
        for team in field {
            XCTAssertNotEqual(TeamFlag.emoji(for: team), TeamFlag.fallback, team)
        }
    }

    func testOrdinalSuffixes() {
        let expected = [1: "1st", 2: "2nd", 3: "3rd", 4: "4th", 11: "11th", 12: "12th", 13: "13th", 21: "21st", 22: "22nd"]
        for (number, text) in expected {
            XCTAssertEqual(number.ordinal, text)
        }
    }

    func testScoreNoteDescribesExtraTimeAndPenalties() {
        let normal = Score(fullTime: ScoreLine(home: 2, away: 0), halfTime: ScoreLine(home: 1, away: 0))
        let extra = Score(
            fullTime: ScoreLine(home: 1, away: 1), halfTime: ScoreLine(home: 0, away: 0),
            extraTime: ScoreLine(home: 2, away: 1)
        )
        let shootout = Score(
            fullTime: ScoreLine(home: 1, away: 1), halfTime: ScoreLine(home: 0, away: 0),
            extraTime: ScoreLine(home: 1, away: 1), penalties: ScoreLine(home: 4, away: 3)
        )

        XCTAssertNil(normal.note)
        XCTAssertEqual(extra.note, "After extra time")
        XCTAssertEqual(shootout.note, "4–3 on penalties")
    }
}
