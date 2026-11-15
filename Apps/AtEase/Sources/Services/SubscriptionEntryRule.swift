import Foundation

enum SubscriptionEntryRule {
    static let minimumSessionsBeforeEntry = 3

    static func shouldShowEntry(afterSessionCount count: Int) -> Bool {
        count >= minimumSessionsBeforeEntry
    }
}
