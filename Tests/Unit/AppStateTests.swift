import XCTest
import CoreAudio
@testable import SoundFlow

final class AppStateTests: XCTestCase {

    private var appState: AppState!
    private var userDefaultsSuiteName: String!

    override func setUp() {
        super.setUp()
        userDefaultsSuiteName = "com.soundflow.tests.\(UUID().uuidString)"
        UserDefaults(suiteName: userDefaultsSuiteName)?.removePersistentDomain(forName: userDefaultsSuiteName)
        appState = AppState.shared
    }

    override func tearDown() {
        UserDefaults(suiteName: userDefaultsSuiteName)?.removePersistentDomain(forName: userDefaultsSuiteName)
        super.tearDown()
    }

    // MARK: - Configuration Management

    func testGetDefaultConfiguration() {
        let config = appState.getConfiguration(for: 999)

        XCTAssertEqual(config.deviceId, 999)
        XCTAssertTrue(config.isActive)
    }

    func testUpdateConfiguration() {
        let deviceId: AudioDeviceID = 42

        appState.updateConfiguration(for: deviceId) { config in
            config.outputConfig = ChannelConfiguration(leftVolume: 0.5, rightVolume: 0.5, deviceVolume: 0.8, delayMs: 10.0)
        }

        let updated = appState.getConfiguration(for: deviceId)
        XCTAssertEqual(updated.outputConfig?.leftVolume, 0.5)
        XCTAssertEqual(updated.outputConfig?.delayMs, 10.0)
    }

    func testSetOutputConfiguration() {
        let deviceId: AudioDeviceID = 100
        let config = ChannelConfiguration(leftVolume: 0.75, rightVolume: 0.75, deviceVolume: 0.9, delayMs: 5.0)

        appState.setOutputConfiguration(for: deviceId, config)

        let stored = appState.getConfiguration(for: deviceId)
        XCTAssertEqual(stored.outputConfig, config)
    }

    func testSetInputConfiguration() {
        let deviceId: AudioDeviceID = 200
        let config = ChannelConfiguration(leftVolume: 0.9, rightVolume: 0.9, deviceVolume: 0.85, delayMs: 15.0)

        appState.setInputConfiguration(for: deviceId, config)

        let stored = appState.getConfiguration(for: deviceId)
        XCTAssertEqual(stored.inputConfig, config)
    }
}
