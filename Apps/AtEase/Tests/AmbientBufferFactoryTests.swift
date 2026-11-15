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

    func testExpandedNaturalSoundsAreAvailable() {
        XCTAssertEqual(
            AmbientSound.allCases.map(\.rawValue),
            ["rain", "stream", "insects", "ocean", "forest", "wind"]
        )
    }

    func testAmbientBuffersDoNotCollapseToSilence() {
        for sound in AmbientSound.allCases {
            let buffer = AmbientBufferFactory.buffer(for: sound, duration: 1, sampleRate: 8000)
            guard let samples = buffer.floatChannelData else {
                XCTFail("Expected float channel data")
                continue
            }
            let nonZero = (0 ..< Int(buffer.frameLength)).contains { index in
                abs(Double(samples[0][index])) > 0.0001
            }
            XCTAssertTrue(nonZero, "\(sound.rawValue) should have audible energy")
        }
    }

    func testLegacyAmbientPresetDecodesWithNewSoundLayers() throws {
        let json = #"{"rain":0.4,"stream":0.1,"insects":0.0}"#
        let level = try JSONDecoder().decode(AmbientSoundLevel.self, from: Data(json.utf8))

        XCTAssertEqual(level.rain, 0.4)
        XCTAssertEqual(level.stream, 0.1)
        XCTAssertEqual(level.insects, 0)
        XCTAssertEqual(level.ocean, 0)
        XCTAssertEqual(level.forest, 0)
        XCTAssertEqual(level.wind, 0)
        XCTAssertTrue(level.isActive)
    }
}
