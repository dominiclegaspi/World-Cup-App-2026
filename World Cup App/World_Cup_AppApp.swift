import SwiftData
import SwiftUI

@main
struct World_Cup_AppApp: App {
    @State private var viewModel = TournamentViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
        }
        .modelContainer(for: FavoriteTeam.self)
    }
}
