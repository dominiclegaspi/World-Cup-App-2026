import SwiftUI

struct ScheduleView: View {
    let viewModel: TournamentViewModel

    var body: some View {
        NavigationStack {
            TournamentContent(state: viewModel.state, retry: reload) {
                List {
                    ForEach(viewModel.days) { day in
                        Section {
                            ForEach(day.matches) { match in
                                MatchRow(match: match)
                            }
                        } header: {
                            Text(day.id, format: .dateTime.weekday(.wide).month(.wide).day())
                        }
                    }
                }
            }
            .navigationTitle("Schedule")
        }
    }

    private func reload() {
        Task { await viewModel.load() }
    }
}
