@testable import AtEase
import XCTest

final class MeditationRemoteAudioSchemaTests: XCTestCase {
    private let loader = MeditationContentCatalogLoader()

    func testAcceptsValidRemoteAudio() throws {
        let manifest = AtEaseContentManifest(
            schemaVersion: 2,
            items: [makeItem(audioKind: .remote)]
        )

        XCTAssertNoThrow(try MeditationContentValidator.validate(manifest))
    }

    func testRejectsRemoteAudioWithoutURL() {
        var item = makeItem(audioKind: .remote)
        item.remoteAudio = nil
        let manifest = AtEaseContentManifest(schemaVersion: 2, items: [item])

        XCTAssertThrowsError(try MeditationContentValidator.validate(manifest))
    }

    func testRejectsInsecureRemoteAudio() throws {
        var item = makeItem(audioKind: .remote)
        item.remoteAudio?.url = try XCTUnwrap(URL(string: "http://example.com/audio.m4a"))
        let manifest = AtEaseContentManifest(schemaVersion: 2, items: [item])

        XCTAssertThrowsError(try MeditationContentValidator.validate(manifest))
    }

    func testRejectsUnsupportedAudioExtension() {
        var item = makeItem(audioKind: .remote)
        item.remoteAudio?.fileExtension = "exe"
        let manifest = AtEaseContentManifest(schemaVersion: 2, items: [item])

        XCTAssertThrowsError(try MeditationContentValidator.validate(manifest))
    }

    func testRejectsLocalContentWithRemoteAudio() throws {
        var item = makeItem(audioKind: .scripted)
        item.remoteAudio = try MeditationRemoteAudio(
            url: XCTUnwrap(URL(string: "https://example.com/audio.m4a")),
            fileExtension: "m4a"
        )
        let manifest = AtEaseContentManifest(schemaVersion: 2, items: [item])

        XCTAssertThrowsError(try MeditationContentValidator.validate(manifest))
    }

    private func makeItem(audioKind: MeditationAudioKind) -> MeditationContentItem {
        MeditationContentItem(
            id: "remote-\(UUID().uuidString)",
            title: "Remote",
            subtitle: "",
            teacher: "",
            theme: .sleep,
            durationSeconds: 60,
            audioKind: audioKind,
            isSubscriptionRequired: false,
            steps: [MeditationContentStep(id: "step", title: "练习", text: "保持觉察。", durationSeconds: 60)],
            remoteAudio: audioKind == .remote
                ? MeditationRemoteAudio(
                    url: URL(string: "https://example.com/audio.m4a")!,
                    fileExtension: "m4a"
                )
                : nil
        )
    }
}
