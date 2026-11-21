import Foundation

/// Builds group tables from match results.
///
/// The feed has no standings, so they are computed here. Teams are ranked by
/// points, then goal difference, then goals scored, then name so the order is
/// always deterministic.
///
/// Known simplification: FIFA's official rules compare head-to-head results
/// among tied teams before goal difference. For the 2026 data this gives the
/// same order in all 12 groups, but a different tournament could differ.
enum StandingsCalculator {
    static func tables(from matches: [Match]) -> [GroupTable] {
        var teamsByGroup: [String: [String: Standing]] = [:]

        for match in matches {
            // Knockout matches don't belong in a group table.
            guard let group = match.stage.groupName else { continue }
            let score = match.score.fullTime

            teamsByGroup[group, default: [:]][match.homeTeam, default: Standing(team: match.homeTeam)]
                .record(goalsFor: score.home, goalsAgainst: score.away)
            teamsByGroup[group, default: [:]][match.awayTeam, default: Standing(team: match.awayTeam)]
                .record(goalsFor: score.away, goalsAgainst: score.home)
        }

        return teamsByGroup
            .map { name, teams in
                GroupTable(name: name, standings: teams.values.sorted(by: ranksAbove))
            }
            .sorted { $0.name < $1.name }
    }

    private static func ranksAbove(_ a: Standing, _ b: Standing) -> Bool {
        if a.points != b.points { return a.points > b.points }
        if a.goalDifference != b.goalDifference { return a.goalDifference > b.goalDifference }
        if a.goalsFor != b.goalsFor { return a.goalsFor > b.goalsFor }
        return a.team < b.team
    }
}

extension Stage {
    /// "Group A" for group matches, nil for knockout rounds.
    var groupName: String? {
        if case .group(let name) = self { return name }
        return nil
    }
}
