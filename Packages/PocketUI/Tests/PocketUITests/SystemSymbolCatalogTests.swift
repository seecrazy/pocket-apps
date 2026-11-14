import UIKit
import XCTest

final class SystemSymbolCatalogTests: XCTestCase {
    func testAppSymbolsExistOniOS() {
        let symbols = [
            "arrow.triangle.2.circlepath",
            "arrow.up.arrow.down",
            "arrow.up.forward",
            "bell",
            "bell.badge",
            "brain.head.profile.fill",
            "calendar",
            "calendar.badge.checkmark",
            "calendar.badge.clock",
            "calendar.day.timeline.left",
            "chart.bar.xaxis",
            "checkmark",
            "checkmark.circle",
            "clock",
            "envelope",
            "envelope.open.fill",
            "envelope.open.fill",
            "exclamationmark.triangle",
            "eye",
            "eye.slash",
            "flame",
            "folder",
            "gear",
            "gearshape",
            "house",
            "house.fill",
            "iphone",
            "iphone",
            "link",
            "lock.open",
            "mic.badge.xmark",
            "music.note.list",
            "number",
            "play.fill",
            "record.circle",
            "sparkles",
            "square.stack.3d.up",
            "tag",
            "timer",
            "tray",
            "tray.full",
            "waveform",
            "waveform.badge.magnifyingglass",
        ]

        for symbol in symbols {
            XCTAssertNotNil(UIImage(systemName: symbol), "Missing SF Symbol: \(symbol)")
        }
    }
}
