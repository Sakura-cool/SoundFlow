import XCTest
import CoreAudio
@testable import SoundFlow

final class CrashDiagnosisTests: XCTestCase {

    private var audioManager: AudioDeviceManager!

    override func setUp() {
        super.setUp()
        audioManager = AudioDeviceManager.shared
    }

    func testRefreshDeviceListDoesNotCrash() {
        audioManager.refreshDeviceList()
        XCTAssertFalse(audioManager.outputDevices.isEmpty, "Should enumerate output devices")
        XCTAssertFalse(audioManager.inputDevices.isEmpty, "Should enumerate input devices")
    }

    func testAllDevicePropertiesAreValid() {
        audioManager.refreshDeviceList()

        for device in audioManager.outputDevices {
            XCTAssertFalse(device.name.isEmpty, "Device name should not be empty")
            XCTAssertGreaterThan(device.outputChannelCount, 0, "Output device should have channels: \(device.name)")
        }

        for device in audioManager.inputDevices {
            XCTAssertFalse(device.name.isEmpty, "Device name should not be empty")
            XCTAssertGreaterThan(device.inputChannelCount, 0, "Input device should have channels: \(device.name)")
        }
    }

    func testVolumeAccessOnAllOutputDevices() {
        audioManager.refreshDeviceList()

        for device in audioManager.outputDevices {
            var address = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyVolumeScalar,
                mScope: kAudioDevicePropertyScopeOutput,
                mElement: 0
            )
            if AudioObjectHasProperty(device.id, &address) {
                let vol = audioManager.getVolume(deviceID: device.id, channel: 0, isOutput: true)
                XCTAssertGreaterThanOrEqual(vol, 0.0, "Volume should be >= 0 for \(device.name)")
                XCTAssertLessThanOrEqual(vol, 1.0, "Volume should be <= 1 for \(device.name)")
            }
        }
    }

    func testVolumeAccessOnAllInputDevices() {
        audioManager.refreshDeviceList()

        for device in audioManager.inputDevices {
            var address = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyVolumeScalar,
                mScope: kAudioDevicePropertyScopeInput,
                mElement: 0
            )
            if AudioObjectHasProperty(device.id, &address) {
                let vol = audioManager.getVolume(deviceID: device.id, channel: 0, isOutput: false)
                XCTAssertGreaterThanOrEqual(vol, 0.0, "Volume should be >= 0 for \(device.name)")
                XCTAssertLessThanOrEqual(vol, 1.0, "Volume should be <= 1 for \(device.name)")
            }
        }
    }

    func testPanAccessOnAllOutputDevices() {
        audioManager.refreshDeviceList()

        for device in audioManager.outputDevices {
            var address = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyStereoPan,
                mScope: kAudioDevicePropertyScopeOutput,
                mElement: kAudioObjectPropertyElementMain
            )
            if AudioObjectHasProperty(device.id, &address) {
                let pan = audioManager.getPan(deviceID: device.id, isOutput: true)
                XCTAssertGreaterThanOrEqual(pan, -1.0, "Pan should be >= -1 for \(device.name)")
                XCTAssertLessThanOrEqual(pan, 1.0, "Pan should be <= 1 for \(device.name)")
            }
        }
    }

    func testSetVolumeDoesNotCrashOnAnyOutputDevice() {
        audioManager.refreshDeviceList()

        for device in audioManager.outputDevices {
            var address = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyVolumeScalar,
                mScope: kAudioDevicePropertyScopeOutput,
                mElement: 0
            )
            if AudioObjectHasProperty(device.id, &address) {
                let original = audioManager.getVolume(deviceID: device.id, channel: 0, isOutput: true)
                audioManager.setVolume(0.5, deviceID: device.id, channel: 0, isOutput: true)
                audioManager.setVolume(original, deviceID: device.id, channel: 0, isOutput: true)
            }
        }
    }

    func testSetPanDoesNotCrashOnAnyOutputDevice() {
        audioManager.refreshDeviceList()

        for device in audioManager.outputDevices {
            var address = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyStereoPan,
                mScope: kAudioDevicePropertyScopeOutput,
                mElement: kAudioObjectPropertyElementMain
            )
            if AudioObjectHasProperty(device.id, &address) {
                let original = audioManager.getPan(deviceID: device.id, isOutput: true)
                audioManager.setPan(0.0, deviceID: device.id, isOutput: true)
                audioManager.setPan(original, deviceID: device.id, isOutput: true)
            }
        }
    }

    func testMultipleRapidRefreshesDoNotCrash() {
        for _ in 0..<10 {
            audioManager.refreshDeviceList()
        }
        XCTAssertFalse(audioManager.outputDevices.isEmpty)
    }

    func testDefaultOutputDeviceIsValid() {
        let defaultID = getDefaultOutputDeviceID()
        XCTAssertNotEqual(defaultID, 0, "Default output device should be valid")

        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceNameCFString,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        XCTAssertTrue(AudioObjectHasProperty(defaultID, &address),
                      "Default output device should have a name property")
    }

    func testDefaultInputDeviceIsValid() {
        let defaultID = getDefaultInputDeviceID()
        XCTAssertNotEqual(defaultID, 0, "Default input device should be valid")

        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceNameCFString,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        XCTAssertTrue(AudioObjectHasProperty(defaultID, &address),
                      "Default input device should have a name property")
    }

    func testToggleOutputDeviceDoesNotCrash() {
        audioManager.refreshDeviceList()
        guard let device = audioManager.outputDevices.first else { return }

        audioManager.selectedOutputDevices.removeAll()
        audioManager.toggleOutputDevice(device)
        audioManager.toggleOutputDevice(device)

        XCTAssertFalse(audioManager.selectedOutputDevices.contains(device.id))
    }

    func testSelectInputDeviceDoesNotCrash() {
        audioManager.refreshDeviceList()
        guard let device = audioManager.inputDevices.first else { return }

        audioManager.selectInputDevice(device)
        XCTAssertEqual(audioManager.selectedInputDevice?.id, device.id)
    }

    func testTeardownDoesNotCrash() {
        audioManager.teardownAggregateDevice()
        audioManager.teardownAggregateDevice()
        audioManager.teardownAggregateDevice()

        let defaultID = getDefaultOutputDeviceID()
        XCTAssertNotEqual(defaultID, 0)
    }

    func testAppStateConfigurationDoesNotCrash() {
        let appState = AppState.shared

        for device in audioManager.outputDevices {
            let config = appState.getConfiguration(for: device.id)
            XCTAssertNotNil(config)
        }
    }

    func testAppStatePersistenceDoesNotCrash() {
        let appState = AppState.shared
        let testID: AudioDeviceID = 999999

        let config = ChannelConfiguration(leftVolume: 0.7, rightVolume: 0.3, delayMs: 10.0)
        appState.setOutputConfiguration(for: testID, config)

        let loaded = appState.getConfiguration(for: testID)
        XCTAssertEqual(loaded.outputConfig?.leftVolume, 0.7)
    }

    private func getDefaultOutputDeviceID() -> AudioDeviceID {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var deviceID: AudioDeviceID = 0
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &deviceID)
        return deviceID
    }

    private func getDefaultInputDeviceID() -> AudioDeviceID {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var deviceID: AudioDeviceID = 0
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &deviceID)
        return deviceID
    }
}
