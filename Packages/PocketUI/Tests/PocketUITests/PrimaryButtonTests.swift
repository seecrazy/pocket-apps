@testable import PocketUI
import SwiftUI
import XCTest

final class PrimaryButtonTests: XCTestCase {
    func testButtonCanBeCreated() {
        let button = PrimaryButton("确认") {}
        XCTAssertNotNil(button)
    }

    func testReusableComponentsCanBeCreated() {
        XCTAssertNotNil(EmptyStateView(systemImage: "tray", title: "空", message: "没有内容"))
        XCTAssertNotNil(SettingRow(systemImage: "gear", title: "设置", detail: "说明"))
        XCTAssertNotNil(CardContainer { Text("内容") })
        XCTAssertNotNil(ArchiveRow(title: "归档", detail: "说明") { Text("内容") })
        XCTAssertNotNil(
            OnboardingPage(
                systemImage: "house",
                title: "标题",
                message: "说明",
                bullets: ["要点"],
                primaryTitle: "开始"
            ) {}
        )
        XCTAssertNotNil(
            SettingSection(title: "设置") {
                Text("内容")
            }
        )
        XCTAssertNotNil(
            TrendBarChart(
                title: "趋势",
                unit: "分钟",
                data: [TrendBarChart.TrendValue(label: "一", value: 2)]
            )
        )
    }
}
