@testable import SoloGuard
import XCTest

final class SoloGuardSafetyServiceTests: XCTestCase {
    func testGeneratesExplicitSafetyStatus() {
        let date = Date(timeIntervalSince1970: 1_760_000_000)
        let status = SoloGuardSafetyStatus(
            contactName: "Mum",
            planTitle: "晚安确认",
            lastCheckInAt: date,
            streak: 3,
            needsAttention: true,
            generatedAt: date
        )

        let message = SoloGuardSafetyMessage.statusText(status)
        XCTAssertTrue(message.contains("需要查看"))
        XCTAssertTrue(message.contains("晚安确认"))
        XCTAssertTrue(message.contains("连续确认：3 天"))
    }

    func testValidatesPhoneURL() {
        XCTAssertNotNil(SoloGuardSafetyMessage.callURL(phone: "+8613800138000"))
        XCTAssertNil(SoloGuardSafetyMessage.callURL(phone: "not a phone"))

        let sms = SoloGuardSafetyMessage.smsURL(phone: "13800138000", body: "状态")
        XCTAssertNotNil(sms)
    }
}
