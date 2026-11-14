import Foundation

struct SoloGuardSafetyStatus: Equatable {
    let contactName: String?
    let planTitle: String?
    let lastCheckInAt: Date?
    let streak: Int
    let needsAttention: Bool
    let generatedAt: Date
}

enum SoloGuardSafetyMessage {
    static func statusText(_ status: SoloGuardSafetyStatus) -> String {
        var lines: [String] = []
        lines.append(status.needsAttention ? "【SoloGuard 需要查看】" : "【SoloGuard 安全状态】")
        if let planTitle = status.planTitle {
            lines.append("最近计划：\(planTitle)")
        }
        if let lastCheckInAt = status.lastCheckInAt {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm"
            lines.append("最近确认：\(formatter.string(from: lastCheckInAt))")
        } else {
            lines.append("最近确认：暂无记录")
        }
        lines.append("连续确认：\(status.streak) 天")
        lines.append("状态生成：\(status.generatedAt.formatted(date: .abbreviated, time: .shortened))")
        return lines.joined(separator: "\n")
    }

    static func smsURL(phone: String, body: String) -> URL? {
        let encoded = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "sms:\(phone)&body=\(encoded)")
    }

    static func callURL(phone: String) -> URL? {
        let trimmed = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.allSatisfy({ $0.isNumber || $0 == "+" || $0 == "-" }) else { return nil }
        return URL(string: "tel:\(trimmed)")
    }
}
