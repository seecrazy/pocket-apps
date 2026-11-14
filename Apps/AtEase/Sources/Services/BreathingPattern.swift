import Foundation

enum BreathingPattern: String, CaseIterable, Identifiable {
    case relaxing
    case box
    case sos

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .relaxing: return "4-7-8 放松"
        case .box: return "箱式呼吸"
        case .sos: return "1 分钟 SOS"
        }
    }

    var subtitle: String {
        switch self {
        case .relaxing: return "适合睡前与情绪回落"
        case .box: return "适合恢复专注与稳定"
        case .sos: return "急性焦虑时的快速镇静"
        }
    }

    var phases: [BreathingPhase] {
        switch self {
        case .relaxing: return [.inhale(seconds: 4), .hold(seconds: 7), .exhale(seconds: 8)]
        case .box: return [.inhale(seconds: 4), .hold(seconds: 4), .exhale(seconds: 4), .hold(seconds: 4)]
        case .sos: return [.inhale(seconds: 4), .exhale(seconds: 6)]
        }
    }
}

enum BreathingPhase: Equatable {
    case inhale(seconds: Int)
    case hold(seconds: Int)
    case exhale(seconds: Int)

    var seconds: Int {
        switch self {
        case let .inhale(seconds), let .hold(seconds), let .exhale(seconds):
            return seconds
        }
    }

    var title: String {
        switch self {
        case .inhale: return "吸气"
        case .hold: return "屏息"
        case .exhale: return "呼气"
        }
    }

    var scale: CGFloat {
        switch self {
        case .inhale: return 1.8
        case .hold: return 1.8
        case .exhale: return 1.0
        }
    }

    var opacity: Double {
        switch self {
        case .inhale: return 0.8
        case .hold: return 0.72
        case .exhale: return 0.5
        }
    }
}
