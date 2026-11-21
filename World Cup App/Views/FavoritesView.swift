import SwiftData
import SwiftUI

struct FavoritesView: View {
    let viewModel: TournamentViewModel

    @Query(sort: \FavoriteTeam.addedAt) private var favorites: [FavoriteTeam]

    var body: some View {
        NavigationStack {
            Group {
                if favorites.isEmpty {
                    ContentUnavailableView(
                        "No favorites yet",
                        systemImage: "star",
                        description: Text("Open a team and tap the star to follow it.")
                    )
                } else {
                    List(favorites) { favorite in
                        NavigationLink(value: favorite.name) {
                            FavoriteRow(team: favorite.name, summary: viewModel.summary(for: favorite.name))
                        }
                    }
                }
            }
            .navigationTitle("Favorites")
            .navigationDestination(for: String.self) { team in
                TeamView(team: team, viewModel: viewModel)
            }
        }
    }
}

private struct FavoriteRow: View {
    let team: String
    let summary: TeamSummary

    var body: some View {
        HStack(spacing: 12) {
            Text(TeamFlag.emoji(for: team)).font(.largeTitle)
            VStack(alignment: .leading, spacing: 2) {
                Text(team).font(.headline)
                if let group = summary.groupName, let rank = summary.groupRank {
                    Text("\(group) · \(rank.ordinal)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }
}
