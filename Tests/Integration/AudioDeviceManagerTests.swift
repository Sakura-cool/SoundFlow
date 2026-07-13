import XCTest
import CoreAudio
@testable import SoundFlow

final class AudioDeviceManagerTests: XCTestCase {

    private var audioManager: AudioDeviceManager!

    override func setUp() {
        super.setUp()
        audioManager = AudioDeviceManager.shared
    }

    // MARK: - Device Enumeration

    func testRefreshDeviceList() {
        audioManager.refreshDeviceList()

        XCTAssertFalse(audioManager.outputDevices.isEmpty, "Should have at least one output device")
    }

    func testOutputDevicesHaveRequiredProperties() {
        audioManager.refreshDeviceList()

        for device in audioManager.outputDevices {
            XCTAssertFalse(device.name.isEmpty, "Device name should not be empty")
            XCTAssertFalse(device.manufacturer.isEmpty, "Device manufacturer should not be empty")
            XCTAssertTrue(device.outputChannelCount > 0, "Output device should have output channels")
        }
    }

    func testInputDevicesHaveRequiredProperties() {
        audioManager.refreshDeviceList()

        for device in audioManager.inputDevices {
            XCTAssertFalse(device.name.isEmpty, "Device name should not be empty")
            XCTAssertFalse(device.manufacturer.isEmpty, "Device manufacturer should not be empty")
            XCTAssertTrue(device.inputChannelCount > 0, "Input device should have input channels")
        }
    }

    // MARK: - Default Device Selection

    func testSelectedOutputDeviceExists() {
        audioManager.refreshDeviceList()

        if let selectedID = audioManager.selectedOutputDevices.first {
            XCTAssertTrue(audioManager.outputDevices.contains { $0.id == selectedID },
                         "Selected output device should be in the list of output devices")
        }
    }

    func testSelectedInputDeviceExists() {
        audioManager.refreshDeviceList()

        if let selected = audioManager.selectedInputDevice {
            XCTAssertTrue(audioManager.inputDevices.contains(selected),
                         "Selected input device should be in the list of input devices")
        }
    }

    // MARK: - Device Selection

    func testSelectOutputDevice() {
        audioManager.refreshDeviceList()

        guard let firstDevice = audioManager.outputDevices.first else {
            XCTFail("No output devices available")
            return
        }

        audioManager.toggleOutputDevice(firstDevice)
        XCTAssertTrue(audioManager.selectedOutputDevices.contains(firstDevice.id))
    }

    func testSelectInputDevice() {
        audioManager.refreshDeviceList()

        guard let firstDevice = audioManager.inputDevices.first else {
            XCTFail("No input devices available")
            return
        }

        audioManager.selectInputDevice(firstDevice)
        XCTAssertEqual(audioManager.selectedInputDevice?.id, firstDevice.id)
    }

    // MARK: - Volume Control (skips devices without volume support)

    func testGetVolumeForOutputDevice() {
        audioManager.refreshDeviceList()

        guard let device = audioManager.outputDevices.first else {
            XCTFail("No output devices available")
            return
        }

        guard hasVolumeProperty(deviceID: device.id, isOutput: true) else {
            return
        }

        let volume = audioManager.getVolume(deviceID: device.id, channel: 0, isOutput: true)
        XCTAssertTrue(volume >= 0.0 && volume <= 1.0, "Volume should be between 0 and 1")
    }

    func testSetVolumeForOutputDevice() {
        audioManager.refreshDeviceList()

        guard let device = audioManager.outputDevices.first else {
            XCTFail("No output devices available")
            return
        }

        guard hasVolumeProperty(deviceID: device.id, isOutput: true) else {
            return
        }

        let originalVolume = audioManager.getVolume(deviceID: device.id, channel: 0, isOutput: true)

        audioManager.setVolume(0.5, deviceID: device.id, channel: 0, isOutput: true)
        let newVolume = audioManager.getVolume(deviceID: device.id, channel: 0, isOutput: true)

        XCTAssertEqual(newVolume, 0.5, accuracy: 0.01)

        audioManager.setVolume(originalVolume, deviceID: device.id, channel: 0, isOutput: true)
    }

    // MARK: - Pan Control (skips devices without pan support)

    func testGetPanForOutputDevice() {
        audioManager.refreshDeviceList()

        guard let device = audioManager.outputDevices.first else {
            XCTFail("No output devices available")
            return
        }

        guard hasPanProperty(deviceID: device.id, isOutput: true) else {
            return
        }

        let pan = audioManager.getPan(deviceID: device.id, isOutput: true)
        XCTAssertTrue(pan >= -1.0 && pan <= 1.0, "Pan should be between -1 and 1")
    }

    func testSetPanForOutputDevice() {
        audioManager.refreshDeviceList()

        guard let device = audioManager.outputDevices.first else {
            XCTFail("No output devices available")
            return
        }

        guard hasPanProperty(deviceID: device.id, isOutput: true) else {
            return
        }

        let originalPan = audioManager.getPan(deviceID: device.id, isOutput: true)

        audioManager.setPan(0.5, deviceID: device.id, isOutput: true)
        let newPan = audioManager.getPan(deviceID: device.id, isOutput: true)

        XCTAssertEqual(newPan, 0.5, accuracy: 0.01)

        audioManager.setPan(originalPan, deviceID: device.id, isOutput: true)
    }

    // MARK: - Helpers

    private func hasVolumeProperty(deviceID: AudioDeviceID, isOutput: Bool) -> Bool {
        let scope: AudioObjectPropertyScope = isOutput ? kAudioDevicePropertyScopeOutput : kAudioDevicePropertyScopeInput
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: scope,
            mElement: 0
        )
        return AudioObjectHasProperty(deviceID, &propertyAddress)
    }

    private func hasPanProperty(deviceID: AudioDeviceID, isOutput: Bool) -> Bool {
        let scope: AudioObjectPropertyScope = isOutput ? kAudioDevicePropertyScopeOutput : kAudioDevicePropertyScopeInput
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStereoPan,
            mScope: scope,
            mElement: kAudioObjectPropertyElementMain
        )
        return AudioObjectHasProperty(deviceID, &propertyAddress)
    }
}
