import PocketCore
import PocketUI
import SwiftData
import SwiftUI
import UIKit

struct AtEaseBodyScanView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var activeRegion: BodyRegion?
    @State private var visitedRegions: Set<BodyRegion> = []
    @State private var startedAt = Date()
    @State private var hapticPlayer: any AtEaseHapticPlayer = SystemAtEaseHapticPlayer()
    @State private var healthWriter = HealthKitMindfulMinutesWriter()

    var body: some View {
        ZStack {
            AtEaseDesignTokens.canvas.ignoresSafeArea()

            VStack(spacing: 32) {
                HStack {
                    Button {
                        saveSession()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body)
                            .foregroundStyle(AtEaseDesignTokens.textSecondary.opacity(0.4))
                    }
                    .accessibilityLabel("关闭")
                    .padding(.leading, 24)
                    Spacer()
                }
                .padding(.top, 24)

                Spacer()

                GeometryReader { proxy in
                    BodyOutlineView(activeRegion: activeRegion)
                        .gesture(
                            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                                .onChanged { value in
                                    let region = BodyRegion.region(for: value.location, in: proxy.size)
                                    select(region)
                                }
                        )
                }
                .frame(maxWidth: 300, maxHeight: 460)

                Spacer()

                Text(footer)
                    .font(.subheadline)
                    .foregroundStyle(AtEaseDesignTokens.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                PrimaryButton("结束") {
                    saveSession()
                    dismiss()
                }
                .padding(.horizontal, AtEaseDesignTokens.pagePadding)
                .padding(.bottom, 48)
            }
        }
        .navigationBarHidden(true)
    }

    private var footer: String {
        if visitedRegions.isEmpty {
            return "手指沿身体轮廓慢慢移动。没有节奏要求。"
        }
        if visitedRegions.count == BodyRegion.allCases.count {
            return "所有区域都经过了。可以在你想停的时候结束。"
        }
        return "经过 \(visitedRegions.count)/\(BodyRegion.allCases.count) 个区域。"
    }

    private func select(_ region: BodyRegion?) {
        guard let region else {
            activeRegion = nil
            return
        }
        if activeRegion != region {
            activeRegion = region
            hapticPlayer.phaseChange()
        }
        visitedRegions.insert(region)
    }

    private func saveSession() {
        let endedAt = Date()
        let seconds = max(1, Int(Date().timeIntervalSince(startedAt)))
        let session = PracticeSessionModel(
            kind: .bodyScan,
            startedAt: startedAt,
            endedAt: endedAt,
            mindfulSeconds: seconds
        )
        modelContext.insert(session)
        try? modelContext.save()
        Task {
            _ = await healthWriter.save(seconds: Double(seconds), startedAt: startedAt, endedAt: endedAt)
        }
    }
}

private struct BodyOutlineView: View {
    let activeRegion: BodyRegion?

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                BodyPath()
                    .stroke(AtEaseDesignTokens.textPrimary.opacity(0.45), lineWidth: 1.5)
                    .frame(width: proxy.size.width, height: proxy.size.height)

                ForEach(BodyRegion.allCases) { region in
                    regionHighlight(region)
                }
            }
        }
    }

    @ViewBuilder
    private func regionHighlight(_ region: BodyRegion) -> some View {
        let isActive = activeRegion == region
        RoundedRectangle(cornerRadius: region.cornerRadius)
            .fill(AtEaseDesignTokens.accentBreath.opacity(isActive ? 0.5 : 0.08))
            .frame(width: region.width, height: region.height)
            .position(region.center)
    }
}

private struct BodyPath: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            let width = rect.width
            let height = rect.height

            path.move(to: CGPoint(x: width * 0.50, y: height * 0.06))
            path.addLine(to: CGPoint(x: width * 0.58, y: height * 0.18))
            path.addLine(to: CGPoint(x: width * 0.68, y: height * 0.26))
            path.addLine(to: CGPoint(x: width * 0.64, y: height * 0.46))
            path.addLine(to: CGPoint(x: width * 0.68, y: height * 0.72))
            path.addLine(to: CGPoint(x: width * 0.58, y: height * 0.96))
            path.addLine(to: CGPoint(x: width * 0.50, y: height * 0.78))
            path.addLine(to: CGPoint(x: width * 0.42, y: height * 0.96))
            path.addLine(to: CGPoint(x: width * 0.32, y: height * 0.72))
            path.addLine(to: CGPoint(x: width * 0.36, y: height * 0.46))
            path.addLine(to: CGPoint(x: width * 0.32, y: height * 0.26))
            path.addLine(to: CGPoint(x: width * 0.42, y: height * 0.18))
            path.closeSubpath()
        }
    }
}

enum BodyRegion: String, CaseIterable, Identifiable {
    case head
    case shoulders
    case chest
    case abdomen
    case arms
    case legs
    case feet

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .head: return "头颈"
        case .shoulders: return "肩颈"
        case .chest: return "胸腔"
        case .abdomen: return "腹部"
        case .arms: return "手臂"
        case .legs: return "腿"
        case .feet: return "足部"
        }
    }

    var center: CGPoint {
        switch self {
        case .head: return CGPoint(x: 0.50, y: 0.08)
        case .shoulders: return CGPoint(x: 0.50, y: 0.21)
        case .chest: return CGPoint(x: 0.50, y: 0.34)
        case .abdomen: return CGPoint(x: 0.50, y: 0.48)
        case .arms: return CGPoint(x: 0.50, y: 0.32)
        case .legs: return CGPoint(x: 0.50, y: 0.65)
        case .feet: return CGPoint(x: 0.50, y: 0.92)
        }
    }

    var width: CGFloat {
        switch self {
        case .head: return 0.24
        case .shoulders: return 0.58
        case .chest: return 0.38
        case .abdomen: return 0.34
        case .arms: return 0.72
        case .legs: return 0.36
        case .feet: return 0.36
        }
    }

    var height: CGFloat {
        switch self {
        case .head: return 0.09
        case .shoulders: return 0.10
        case .chest: return 0.12
        case .abdomen: return 0.12
        case .arms: return 0.12
        case .legs: return 0.22
        case .feet: return 0.08
        }
    }

    var cornerRadius: CGFloat {
        switch self {
        case .head: return 30
        case .shoulders, .arms: return 24
        default: return 18
        }
    }

    static func region(for point: CGPoint, in size: CGSize) -> BodyRegion? {
        allCases.first { region in
            CGRect(
                x: region.center.x * size.width - (region.width * size.width / 2),
                y: region.center.y * size.height - (region.height * size.height / 2),
                width: region.width * size.width,
                height: region.height * size.height
            ).contains(point)
        }
    }
}
