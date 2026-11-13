import Foundation
import os

public enum PocketLog {
    public static func logger(subsystem: String = Bundle.main.bundleIdentifier ?? "com.pocketapps", category: String) -> Logger {
        Logger(subsystem: subsystem, category: category)
    }
}
