import Foundation

/// All matches kicking off on one calendar day.
struct MatchDay: Identifiable, Hashable {
    /// Start of the day in the calendar used to build it.
    let id: Date
    let matches: [Match]
}

enum ScheduleBuilder {
    /// Groups matches by the day they start, in the given calendar's time zone,
    /// so the schedule reads correctly for wherever the viewer is.
    static func days(from matches: [Match], calendar: Calendar = .current) -> [MatchDay] {
        Dictionary(grouping: matches) { calendar.startOfDay(for: $0.kickoff) }
            .map { day, matches in
                MatchDay(id: day, matches: matches.sorted(by: kicksOffEarlier))
            }
            .sorted { $0.id < $1.id }
    }

    private static func kicksOffEarlier(_ a: Match, _ b: Match) -> Bool {
        a.kickoff == b.kickoff ? a.id < b.id : a.kickoff < b.kickoff
    }
}
