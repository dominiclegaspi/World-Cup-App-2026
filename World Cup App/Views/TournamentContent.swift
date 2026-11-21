import SwiftUI

/// Shows a spinner, an error with a retry button, or the screen's real content,
/// depending on the load state. Every data screen shares this.
struct TournamentContent<Content: View>: View {
    let state: LoadState<[Match]>
    let retry: () -> Void
    private let content: Content

    init(
        state: LoadState<[Match]>,
        retry: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.state = state
        self.retry = retry
        self.content = content()
    }

    var body: some View {
        switch state {
        case .idle, .loading:
            ProgressView("Loading matches…")
        case .failed(let message):
            ContentUnavailableView {
                Label("Couldn't load matches", systemImage: "wifi.slash")
            } description: {
                Text(message)
            } actions: {
                Button("Try Again", action: retry)
            }
        case .loaded:
            content
        }
    }
}
