import Foundation
import SwiftData

/// A team the user follows, saved on the device.
@Model
final class FavoriteTeam {
    @Attribute(.unique) var name: String
    var addedAt: Date

    init(name: String, addedAt: Date = .now) {
        self.name = name
        self.addedAt = addedAt
    }
}

/// Adds and removes favorites. Kept separate from the views so it can be tested
/// against an in-memory store.
@MainActor
struct FavoritesStore {
    let context: ModelContext

    func isFavorite(_ team: String) -> Bool {
        existing(team) != nil
    }

    func toggle(_ team: String) {
        if let favorite = existing(team) {
            context.delete(favorite)
        } else {
            context.insert(FavoriteTeam(name: team))
        }
        try? context.save()
    }

    private func existing(_ team: String) -> FavoriteTeam? {
        var descriptor = FetchDescriptor<FavoriteTeam>(predicate: #Predicate { $0.name == team })
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }
}
