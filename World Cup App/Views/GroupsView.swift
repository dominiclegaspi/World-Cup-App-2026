import SwiftUI

struct GroupsView: View {
    let viewModel: TournamentViewModel

    var body: some View {
        NavigationStack {
            TournamentContent(state: viewModel.state, retry: reload) {
                List {
                    Section { QualificationLegend() }
                        .listRowBackground(Color.clear)

                    ForEach(viewModel.groupTables) { table in
                        Section {
                            StandingsHeader()
                            ForEach(Array(table.standings.enumerated()), id: \.element.id) { index, standing in
                                NavigationLink(value: standing.team) {
                                    StandingRow(rank: index + 1, standing: standing)
                                }
                            }
                        } header: {
                            Text(table.name)
                                .font(.headline)
                                .foregroundStyle(Theme.pitch)
                        }
                    }
                }
            }
            .navigationTitle("Groups")
            .navigationDestination(for: String.self) { team in
                TeamView(team: team, viewModel: viewModel)
            }
        }
    }

    private func reload() {
        Task { await viewModel.load() }
    }
}

/// Column widths shared by the header and the rows so they line up.
private enum Column {
    static let rank: CGFloat = 16
    static let played: CGFloat = 28
    static let goalDifference: CGFloat = 36
    static let points: CGFloat = 32
}

private struct StandingsHeader: View {
    var body: some View {
        HStack {
            Spacer()
            Text("P").frame(width: Column.played)
            Text("GD").frame(width: Column.goalDifference)
            Text("Pts").frame(width: Column.points)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .accessibilityHidden(true)
    }
}

private struct StandingRow: View {
    let rank: Int
    let standing: Standing

    var body: some View {
        HStack {
            Capsule()
                .fill(rank.qualificationColor)
                .frame(width: 4, height: 26)
            Text("\(rank)")
                .foregroundStyle(.secondary)
                .frame(width: Column.rank, alignment: .leading)
            Text("\(TeamFlag.emoji(for: standing.team)) \(standing.team)")
                .lineLimit(1)
            Spacer()
            Text("\(standing.played)").frame(width: Column.played)
            Text(standing.goalDifference.formatted(.number.sign(strategy: .always(includingZero: false))))
                .frame(width: Column.goalDifference)
            Text("\(standing.points)").bold().frame(width: Column.points)
        }
        .monospacedDigit()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(rank). \(standing.team), \(standing.points) points from \(standing.played) matches"
        )
    }
}

private extension Int {
    /// Top two in a group go through; the eight best third-placed teams may too.
    var qualificationColor: Color {
        switch self {
        case 1, 2: Theme.pitch
        case 3: Theme.gold
        default: .clear
        }
    }
}

private struct QualificationLegend: View {
    var body: some View {
        HStack(spacing: 16) {
            key(color: Theme.pitch, text: "Advances")
            key(color: Theme.gold, text: "Best third-place")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func key(color: Color, text: String) -> some View {
        HStack(spacing: 6) {
            Capsule().fill(color).frame(width: 4, height: 14)
            Text(text)
        }
    }
}
