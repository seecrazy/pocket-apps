import Foundation

enum FocusLockMode: String, CaseIterable, Identifiable {
    case off
    case app

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .off: return "关闭"
        case .app: return "App 内锁定"
        }
    }

    var detail: String {
        switch self {
        case .off: return "不锁定界面，你可以自由离开 App。"
        case .app: return "专注时使用全屏锁定页。不是系统级锁机。"
        }
    }
}
