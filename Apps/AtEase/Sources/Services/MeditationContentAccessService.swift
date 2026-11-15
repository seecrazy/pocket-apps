import Foundation

enum MeditationContentAccess {
    case unlocked
    case subscriptionRequired
}

struct MeditationContentAccessService {
    func access(for item: MeditationContentItem, isSubscribed: Bool) -> MeditationContentAccess {
        guard item.isSubscriptionRequired else {
            return .unlocked
        }
        return isSubscribed ? .unlocked : .subscriptionRequired
    }

    func canPlay(_ item: MeditationContentItem, isSubscribed: Bool) -> Bool {
        access(for: item, isSubscribed: isSubscribed) == .unlocked
    }

    func visibleItems(
        from manifest: AtEaseContentManifest,
        filter: MeditationLibraryFilter,
        favoriteContentIDs: Set<String>,
        isSubscribed: Bool
    ) -> [MeditationContentItem] {
        let freeItems = manifest.items.filter { !$0.isSubscriptionRequired }
        let subscriptionItems = manifest.items.filter(\.isSubscriptionRequired)

        switch filter {
        case .all:
            return freeItems + subscriptionItems
        case .favorites:
            return manifest.items.filter { favoriteContentIDs.contains($0.id) }
        }
    }
}
