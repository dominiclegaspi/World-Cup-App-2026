import Foundation

enum Outcome: Equatable {
    case win, draw, loss
}

extension Score {
    /// Result from one side's point of view. A shootout decides a match that is
    /// level after extra time.
    func outcome(asHome: Bool) -> Outcome {
        func decide(_ line: ScoreLine) -> Outcome? {
            guard line.home != line.away else { return nil }
            return (line.home > line.away) == asHome ? .win : .loss
        }
        if let result = decide(played) { return result }
        if let penalties, let result = decide(penalties) { return result }
        return .draw
    }
}

/// Everything the team screen shows, worked out from the full match list.
struct TeamSummary: Equatable {
    struct Result: Identifiable, Equatable {
        let match: Match
        let opponent: String
        let goalsFor: Int
        let goalsAgainst: Int
        let outcome: Outcome

        var id: String { match.id }
    }

    struct Scorer: Identifiable, Equatable {
        let name: String
        let goals: Int

        var id: String { name }
    }

    let team: String
    let groupName: String?
    let groupRank: Int?
    let standing: Standing?
    let results: [Result]
    let scorers: [Scorer]
}

enum TeamSummaryBuilder {
    static func summary(for team: String, in matches: [Match]) -> TeamSummary {
        let teamMatches = matches
            .filter { $0.homeTeam == team || $0.awayTeam == team }
            .sorted { $0.kickoff == $1.kickoff ? $0.id < $1.id : $0.kickoff < $1.kickoff }

        let results = teamMatches.map { match -> TeamSummary.Result in
            let isHome = match.homeTeam == team
            let line = match.score.played
            return TeamSummary.Result(
                match: match,
                opponent: isHome ? match.awayTeam : match.homeTeam,
                goalsFor: isHome ? line.home : line.away,
                goalsAgainst: isHome ? line.away : line.home,
                outcome: match.score.outcome(asHome: isHome)
            )
        }

        let table = StandingsCalculator.tables(from: matches)
            .first { $0.standings.contains { $0.team == team } }
        let rankIndex = table?.standings.firstIndex { $0.team == team }

        return TeamSummary(
            team: team,
            groupName: table?.name,
            groupRank: rankIndex.map { $0 + 1 },
            standing: rankIndex.flatMap { table?.standings[$0] },
            results: results,
            scorers: scorers(for: team, in: teamMatches)
        )
    }

    /// Goals are listed under the side that benefited, so an own goal appears in
    /// the *opponent's* list under the unlucky player's name. Those are skipped,
    /// because they don't count for the player's own team.
    private static func scorers(for team: String, in matches: [Match]) -> [TeamSummary.Scorer] {
        var tally: [String: Int] = [:]
        for match in matches {
            let goals = match.homeTeam == team ? match.homeGoals : match.awayGoals
            for goal in goals where !goal.isOwnGoal {
                tally[goal.scorer, default: 0] += 1
            }
        }
        return tally
            .map { TeamSummary.Scorer(name: $0.key, goals: $0.value) }
            .sorted { $0.goals == $1.goals ? $0.name < $1.name : $0.goals > $1.goals }
    }
}
