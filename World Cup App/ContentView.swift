import SwiftUI

/// Root of the app: one shared view model feeds every tab, so the tournament
/// is downloaded once.
struct ContentView: View {
    let viewModel: TournamentViewModel

    var body: some View {
        TabView {
            GroupsView(viewModel: viewModel)
                .tabItem { Label("Groups", systemImage: "tablecells") }
            ScheduleView(viewModel: viewModel)
                .tabItem { Label("Schedule", systemImage: "calendar") }
            FavoritesView(viewModel: viewModel)
                .tabItem { Label("Favorites", systemImage: "star") }
        }
        .tint(Theme.pitch)
        .task { await viewModel.load() }
    }
}
