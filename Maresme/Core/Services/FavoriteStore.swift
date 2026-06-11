import Foundation

// FavoriteStore — source of truth for favorite state during a session.
//
// Strategy: the API already embeds is_favorite in every PropertyCard.
// The store keeps a local override table populated by user actions (toggle).
// isFavorite(slug, fallback:) returns the local override if the user has
// acted on this property in the session; otherwise falls back to the API value.
// This avoids a bulk slug-fetch on login while still reflecting changes instantly.
@Observable
final class FavoriteStore {
    var count: Int = 0

    // Per-slug overrides accumulated during the session.
    // Key = slug, value = current favorite state after user action.
    private var localState: [String: Bool] = [:]

    private let service: FavoriteService

    init(service: FavoriteService = FavoriteService()) {
        self.service = service
    }

    // MARK: - Read

    func isFavorite(_ slug: String, fallback: Bool) -> Bool {
        localState[slug] ?? fallback
    }

    // MARK: - Load count (called after login)

    func loadCount() async {
        do {
            count = try await service.count()
        } catch {
            // Non-critical — badge shows 0 until next successful call
        }
    }

    // MARK: - Toggle (optimistic update)

    func toggle(slug: String, currentFavorite: Bool) async {
        let wasOn = localState[slug] ?? currentFavorite

        // Optimistic
        localState[slug] = !wasOn
        count = max(0, wasOn ? count - 1 : count + 1)

        do {
            let result = try await service.toggle(slug: slug)
            // Reconcile with server truth
            localState[slug] = result.favorited
            count             = result.count
        } catch {
            // Revert optimistic change on failure
            localState[slug] = wasOn
            count = max(0, wasOn ? count + 1 : count - 1)
        }
    }

    // MARK: - Seed from loaded list (called by FavoritesViewModel after fetch)
    // Marks all returned slugs as favorites so the store stays coherent
    // even when the user has not manually toggled them.
    func seedFromFavorites(_ slugs: [String]) {
        for slug in slugs {
            if localState[slug] == nil {
                localState[slug] = true
            }
        }
    }

    // MARK: - Clear on logout

    func reset() {
        localState = [:]
        count      = 0
    }
}
