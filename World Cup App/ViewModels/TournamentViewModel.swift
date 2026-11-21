import Foundation
import Observation

/// Loads the tournament once and exposes it in the shapes the screens need.
@MainActor
@Observable
final class TournamentViewModel {
    private(set) var state: LoadState<[Match]> = .idle
    private(set) var groupTables: [GroupTable] = []
    private(set) var days: [MatchDay] = []

    private let service: MatchesProviding
    private let calendar: Calendar

    init(service: MatchesProviding = RemoteMatchesService(), calendar: Calendar = .current) {
        self.service = service
        self.calendar = calendar
    }

    var matches: [Match] {
        if case .loaded(let matches) = state { return matches }
        return []
    }

    func summary(for team: String) -> TeamSummary {
        TeamSummaryBuilder.summary(for: team, in: matches)
    }

    func playerSummary(for player: String, team: String) -> PlayerSummary {
        PlayerSummaryBuilder.summary(for: player, team: team, in: matches)
    }

    func load() async {
        state = .loading
        do {
            let matches = try await service.fetchMatches()
            groupTables = StandingsCalculator.tables(from: matches)
            days = ScheduleBuilder.days(from: matches, calendar: calendar)
            state = .loaded(matches)
        } catch {
            // The view went away mid-load; there is nothing to report.
            guard !Task.isCancelled else {
                state = .idle
                return
            }
            state = .failed(error.localizedDescription)
        }
    }
}
