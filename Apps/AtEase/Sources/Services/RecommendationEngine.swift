import Foundation

struct AtEaseRecommendation: Identifiable, Equatable {
    let id: String
    let title: String
    let durationLabel: String
    let description: String
    let kind: AtEasePracticeKind
    let pattern: BreathingPattern?
    let minutes: Int
}

struct RecommendationEngine {
    func recommendations(for moodLevel: Int) -> [AtEaseRecommendation] {
        switch moodLevel {
        case 0, 1: return calmRecommendations
        case 2: return neutralRecommendations
        default: return agitatedRecommendations
        }
    }

    private var calmRecommendations: [AtEaseRecommendation] {
        [
            AtEaseRecommendation(
                id: "calm-box",
                title: "稳定呼吸",
                durationLabel: "5 分钟",
                description: "保持此刻的平稳，不需要更多。",
                kind: .breath,
                pattern: .box,
                minutes: 5
            ),
            AtEaseRecommendation(
                id: "calm-timer",
                title: "安静静坐",
                durationLabel: "10 分钟",
                description: "没有引导，只有计时。",
                kind: .timer,
                pattern: nil,
                minutes: 10
            ),
            AtEaseRecommendation(
                id: "calm-thought",
                title: "念头放下",
                durationLabel: "随时结束",
                description: "把今天的念头轻轻放下。",
                kind: .thoughtDistancing,
                pattern: nil,
                minutes: 1
            ),
        ]
    }

    private var neutralRecommendations: [AtEaseRecommendation] {
        [
            AtEaseRecommendation(
                id: "neutral-relaxing",
                title: "4-7-8 呼吸",
                durationLabel: "3 分钟",
                description: "让呼吸慢慢变长。",
                kind: .breath,
                pattern: .relaxing,
                minutes: 3
            ),
            AtEaseRecommendation(
                id: "neutral-timer",
                title: "身体落座",
                durationLabel: "5 分钟",
                description: "感受当下支持你的地方。",
                kind: .timer,
                pattern: nil,
                minutes: 5
            ),
            AtEaseRecommendation(
                id: "neutral-sos",
                title: "1 分钟重置",
                durationLabel: "1 分钟",
                description: "给自己一个短暂缓冲。",
                kind: .sos,
                pattern: .sos,
                minutes: 1
            ),
        ]
    }

    private var agitatedRecommendations: [AtEaseRecommendation] {
        [
            AtEaseRecommendation(
                id: "agitated-sos",
                title: "1 分钟 SOS",
                durationLabel: "1 分钟",
                description: "先让呼吸慢下来。",
                kind: .sos,
                pattern: .sos,
                minutes: 1
            ),
            AtEaseRecommendation(
                id: "agitated-relaxing",
                title: "长呼气放松",
                durationLabel: "3 分钟",
                description: "呼气比吸气更长。",
                kind: .breath,
                pattern: .relaxing,
                minutes: 3
            ),
            AtEaseRecommendation(
                id: "agitated-thought",
                title: "念头放下",
                durationLabel: "随时结束",
                description: "把最占据注意力的一句话放下。",
                kind: .thoughtDistancing,
                pattern: nil,
                minutes: 1
            ),
        ]
    }
}
