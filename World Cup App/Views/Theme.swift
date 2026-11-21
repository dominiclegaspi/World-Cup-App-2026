import SwiftUI

/// Colours and small shared components, so every screen looks like one app.
enum Theme {
    static let pitch = Color(red: 0.07, green: 0.46, blue: 0.29)
    static let pitchDark = Color(red: 0.03, green: 0.27, blue: 0.18)
    static let gold = Color(red: 0.95, green: 0.72, blue: 0.20)

    static var banner: LinearGradient {
        LinearGradient(
            colors: [pitch, pitchDark],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

/// White-on-green panel at the top of the team and player screens.
struct HeroPanel<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .foregroundStyle(.white)
            .background(Theme.banner)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

/// One number with a small label under it, used inside a `HeroPanel`.
struct StatTile: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3.bold())
                .monospacedDigit()
            Text(label)
                .font(.caption2.weight(.semibold))
                .opacity(0.8)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label), \(value)")
    }
}

extension View {
    /// Lets a hero panel sit in a `List` without the usual grey row background.
    func heroRow() -> some View {
        self
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)
    }
}
