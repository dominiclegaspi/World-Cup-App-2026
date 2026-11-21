import Foundation

/// Identifies a player on screen. A name alone isn't enough: two teams could
/// each have a "Silva", so the team is part of the identity.
struct PlayerRoute: Hashable {
    let name: String
    let team: String
}

/// Every goal one player scored at the tournament.
struct PlayerSummary: Equatable {
    struct GoalEvent: Identifiable, Equatable {
        let id: String
        let match: Match
        let opponent: String
        let minute: String
        let isPenalty: Bool
    }

    let name: String
    let team: String
    let goals: [GoalEvent]

    var penaltyCount: Int { goals.filter(\.isPenalty).count }
    var matchesScoredIn: Int { Set(goals.map { $0.match.id }).count }
}

enum PlayerSummaryBuilder {
    static func summary(for player: String, team: String, in matches: [Match]) -> PlayerSummary {
        let teamMatches = matches
            .filter { $0.homeTeam == team || $0.awayTeam == team }
            .sorted { $0.kickoff == $1.kickoff ? $0.id < $1.id : $0.kickoff < $1.kickoff }

        var events: [PlayerSummary.GoalEvent] = []
        for match in teamMatches {
            let isHome = match.homeTeam == team
            let goals = isHome ? match.homeGoals : match.awayGoals
            // An own goal is listed under the side that benefited, so the
            // matching name here belongs to the other team. Skip those.
            for (index, goal) in goals.enumerated() where goal.scorer == player && !goal.isOwnGoal {
                events.append(PlayerSummary.GoalEvent(
                    id: "\(match.id)-\(index)",
                    match: match,
                    opponent: isHome ? match.awayTeam : match.homeTeam,
                    minute: goal.minute,
                    isPenalty: goal.isPenalty
                ))
            }
        }
        return PlayerSummary(name: player, team: team, goals: events)
    }
}

/// Builds a YouTube search for a player's tournament highlights. There is no
/// free video API, so the app links out to the search instead of embedding clips.
enum HighlightsLink {
    static func url(player: String, team: String) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "www.youtube.com"
        components.path = "/results"
        components.queryItems = [
            URLQueryItem(name: "search_query", value: "\(player) \(team) World Cup 2026 highlights"),
        ]
        return components.url
    }
}
