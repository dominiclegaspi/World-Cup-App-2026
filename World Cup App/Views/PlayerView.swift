import SwiftUI

struct PlayerView: View {
    let player: PlayerSummary

    var body: some View {
        List {
            Section {
                HeroPanel {
                    VStack(spacing: 12) {
                        Text(TeamFlag.emoji(for: player.team)).font(.system(size: 56))
                        Text(player.name)
                            .font(.title2.bold())
                            .multilineTextAlignment(.center)
                        Text(player.team).font(.subheadline).opacity(0.85)
                        HStack {
                            StatTile(value: "\(player.goals.count)", label: "GOALS")
                            StatTile(value: "\(player.penaltyCount)", label: "PENALTIES")
                            StatTile(value: "\(player.matchesScoredIn)", label: "MATCHES")
                        }
                        .padding(.horizontal)
                    }
                }
                .heroRow()
            }

            Section("Goals") {
                ForEach(player.goals) { goal in
                    GoalRow(goal: goal)
                }
            }

            if let url = HighlightsLink.url(player: player.name, team: player.team) {
                Section {
                    Link(destination: url) {
                        Label("Watch highlights on YouTube", systemImage: "play.rectangle.fill")
                    }
                } footer: {
                    Text("Opens a YouTube search for this player's tournament highlights.")
                }
            }
        }
        .navigationTitle(player.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct GoalRow: View {
    let goal: PlayerSummary.GoalEvent

    var body: some View {
        HStack(spacing: 12) {
            Text("\(goal.minute)'")
                .font(.subheadline.bold())
                .monospacedDigit()
                .frame(width: 52, alignment: .leading)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(TeamFlag.emoji(for: goal.opponent)) \(goal.opponent)")
                Text(goal.match.stage.title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if goal.isPenalty {
                Text("Penalty")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Theme.gold.opacity(0.25), in: Capsule())
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "Minute \(goal.minute) against \(goal.opponent), \(goal.match.stage.title)\(goal.isPenalty ? ", penalty" : "")"
        )
    }
}
