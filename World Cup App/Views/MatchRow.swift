import SwiftUI

struct MatchRow: View {
    let match: Match

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text(match.kickoff, format: .dateTime.hour().minute())
                Text("·")
                Text(match.stage.title)
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(Theme.pitch)

            HStack(alignment: .top, spacing: 8) {
                TeamColumn(team: match.homeTeam)
                ScorePill(score: match.score)
                TeamColumn(team: match.awayTeam)
            }

            Text(match.venue)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(match.homeTeam) versus \(match.awayTeam), \(match.score.summary), \(match.stage.title), \(match.venue)"
        )
    }
}

private struct TeamColumn: View {
    let team: String

    var body: some View {
        VStack(spacing: 4) {
            Text(TeamFlag.emoji(for: team)).font(.largeTitle)
            Text(team)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct ScorePill: View {
    let score: Score

    var body: some View {
        VStack(spacing: 4) {
            Text("\(score.played.home)–\(score.played.away)")
                .font(.title3.bold())
                .monospacedDigit()
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Theme.pitch.opacity(0.12), in: Capsule())
            if let note = score.note {
                Text(note)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 8)
    }
}
