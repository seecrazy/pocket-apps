@testable import AtEase
import AVFAudio
import XCTest

final class AmbientBufferFactoryTests: XCTestCase {
    func testBuffersHaveExpectedLengthAndBoundaries() {
        for sound in AmbientSound.allCases {
            let buffer = AmbientBufferFactory.buffer(for: sound, duration: 2, sampleRate: 8000)
            XCTAssertEqual(buffer.frameLength, 16000)
            guard let channelData = buffer.floatChannelData else {
                return XCTFail("Expected float channel data")
            }
            for index in 0 ..< 16000 {
                let value = Double(channelData[0][index])
                XCTAssertLessThanOrEqual(value, 1)
                XCTAssertGreaterThanOrEqual(value, -1)
            }
        }
    }
}
