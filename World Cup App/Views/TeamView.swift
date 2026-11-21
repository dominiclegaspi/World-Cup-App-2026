import SwiftData
import SwiftUI

struct TeamView: View {
    let team: String
    let viewModel: TournamentViewModel

    @Environment(\.modelContext) private var modelContext
    @Query private var favorites: [FavoriteTeam]

    private var summary: TeamSummary { viewModel.summary(for: team) }
    private var isFavorite: Bool { favorites.contains { $0.name == team } }

    var body: some View {
        List {
            Section { header }

            Section("Results") {
                ForEach(summary.results) { result in
                    ResultRow(result: result)
                }
            }

            if !summary.scorers.isEmpty {
                Section("Goalscorers") {
                    ForEach(summary.scorers) { scorer in
                        NavigationLink(value: PlayerRoute(name: scorer.name, team: team)) {
                            HStack {
                                Text(scorer.name)
                                Spacer()
                                Text("\(scorer.goals) ⚽").monospacedDigit().foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationDestination(for: PlayerRoute.self) { route in
            PlayerView(player: viewModel.playerSummary(for: route.name, team: route.team))
        }
        .navigationTitle(team)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    FavoritesStore(context: modelContext).toggle(team)
                } label: {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                }
                .accessibilityLabel(isFavorite ? "Remove from favorites" : "Add to favorites")
            }
        }
    }

    private var header: some View {
        HeroPanel {
            VStack(spacing: 12) {
                Text(TeamFlag.emoji(for: team)).font(.system(size: 72))
                Text(team).font(.title.bold())
                if let group = summary.groupName, let rank = summary.groupRank {
                    Text("\(group) · \(rank.ordinal)")
                        .font(.subheadline)
                        .opacity(0.85)
                }
                if let standing = summary.standing {
                    HStack {
                        StatTile(value: "\(standing.played)", label: "PLD")
                        StatTile(value: "\(standing.won)", label: "W")
                        StatTile(value: "\(standing.drawn)", label: "D")
                        StatTile(value: "\(standing.lost)", label: "L")
                        StatTile(value: "\(standing.goalsFor)", label: "GF")
                        StatTile(value: "\(standing.goalsAgainst)", label: "GA")
                        StatTile(value: "\(standing.points)", label: "PTS")
                    }
                    .padding(.horizontal, 12)
                }
            }
        }
        .heroRow()
    }
}

private struct ResultRow: View {
    let result: TeamSummary.Result

    var body: some View {
        HStack {
            Text(result.outcome.letter)
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(result.outcome.color, in: Circle())
            VStack(alignment: .leading) {
                Text("\(TeamFlag.emoji(for: result.opponent)) \(result.opponent)")
                Text(result.match.stage.title).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(result.goalsFor)–\(result.goalsAgainst)").bold().monospacedDigit()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(result.outcome.spoken) against \(result.opponent), \(result.goalsFor) to \(result.goalsAgainst), \(result.match.stage.title)"
        )
    }
}

private extension Outcome {
    var letter: String {
        switch self {
        case .win: "W"
        case .draw: "D"
        case .loss: "L"
        }
    }

    var spoken: String {
        switch self {
        case .win: "Win"
        case .draw: "Draw"
        case .loss: "Loss"
        }
    }

    var color: Color {
        switch self {
        case .win: .green
        case .draw: .gray
        case .loss: .red
        }
    }
}
