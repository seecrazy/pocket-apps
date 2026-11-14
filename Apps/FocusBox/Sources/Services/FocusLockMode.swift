import Foundation

enum FocusLockMode: String, CaseIterable, Identifiable {
    case off
    case overlay

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .off: return "关闭"
        case .overlay: return "App 内遮罩"
        }
    }

    var detail: String {
        switch self {
        case .off: return "不锁定界面，你可以自由离开 App。"
        case .overlay: return "专注时使用全屏遮罩页，防止误点；不能阻止系统切屏。"
        }
    }
}
