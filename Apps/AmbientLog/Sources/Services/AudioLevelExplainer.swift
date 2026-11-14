import Foundation

enum AudioLevelExplainer {
    static let explanation = """
    dBFS 是数字音频的相对分贝，0 表示麦克风信号接近数字满量程，可能出现削波；\
    负数表示低于最大信号，越接近 -160 越接近静音。\
    它不是环境噪声的 dB SPL，不能直接当作 30–120 dB 的环境分贝表使用。
    """

    static let scale: [AudioLevelScaleItem] = [
        AudioLevelScaleItem(range: "-120 到 -90", title: "接近静音", detail: "几乎没有声音或麦克风增益很低"),
        AudioLevelScaleItem(range: "-90 到 -70", title: "很安静", detail: "夜间房间、远处的轻微环境声"),
        AudioLevelScaleItem(range: "-70 到 -50", title: "安静", detail: "普通房间背景声、轻微交谈"),
        AudioLevelScaleItem(range: "-50 到 -35", title: "一般说话", detail: "距离不远的人声或日常活动"),
        AudioLevelScaleItem(range: "-35 到 -20", title: "较大声音", detail: "靠近的交谈、咖啡店或街道活动"),
        AudioLevelScaleItem(range: "-20 到 -10", title: "很大声音", detail: "强噪声源，接近增益上限"),
        AudioLevelScaleItem(range: "-10 到 0", title: "接近满格", detail: "可能已经削波，录音会明显刺耳"),
    ]

    static func levelName(for power: Double) -> String {
        switch power {
        case ..<(-100): return "接近静音"
        case -100 ..< -70: return "很安静"
        case -70 ..< -50: return "安静"
        case -50 ..< -35: return "一般说话"
        case -35 ..< -20: return "较大声音"
        case -20 ..< -10: return "很大声音"
        default: return "接近满格"
        }
    }
}

struct AudioLevelScaleItem: Identifiable {
    let range: String
    let title: String
    let detail: String

    var id: String {
        range
    }
}
