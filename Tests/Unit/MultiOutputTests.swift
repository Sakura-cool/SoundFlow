import XCTest
import CoreAudio
@testable import SoundFlow

final class MultiOutputTests: XCTestCase {

    private var audioManager: AudioDeviceManager!

    override func setUp() {
        super.setUp()
        audioManager = AudioDeviceManager.shared
        audioManager.teardownAggregateDevice()
        audioManager.refreshDeviceList()
    }

    override func tearDown() {
        audioManager.teardownAggregateDevice()
        audioManager.selectedOutputDevices.removeAll()
        super.tearDown()
    }

    func testToggleOutputDeviceAddsToSelection() {
        guard let firstDevice = audioManager.outputDevices.first else {
            XCTFail("No output devices available")
            return
        }

        audioManager.selectedOutputDevices.removeAll()
        audioManager.toggleOutputDevice(firstDevice)

        XCTAssertTrue(audioManager.selectedOutputDevices.contains(firstDevice.id))
    }

    func testToggleOutputDeviceRemovesFromSelection() {
        guard let firstDevice = audioManager.outputDevices.first else {
            XCTFail("No output devices available")
            return
        }

        audioManager.selectedOutputDevices.insert(firstDevice.id)
        audioManager.toggleOutputDevice(firstDevice)

        XCTAssertFalse(audioManager.selectedOutputDevices.contains(firstDevice.id))
    }

    func testMultipleDevicesCanBeSelected() {
        guard audioManager.outputDevices.count >= 2 else {
            return
        }

        let device1 = audioManager.outputDevices[0]
        let device2 = audioManager.outputDevices[1]

        audioManager.selectedOutputDevices.removeAll()
        audioManager.toggleOutputDevice(device1)
        audioManager.toggleOutputDevice(device2)

        XCTAssertEqual(audioManager.selectedOutputDevices.count, 2)
        XCTAssertTrue(audioManager.selectedOutputDevices.contains(device1.id))
        XCTAssertTrue(audioManager.selectedOutputDevices.contains(device2.id))
    }

    func testTeardownAggregateDeviceIsIdempotent() {
        audioManager.teardownAggregateDevice()
        audioManager.teardownAggregateDevice()
        audioManager.teardownAggregateDevice()

        let defaultOutput = getDefaultOutputDeviceID()
        XCTAssertNotEqual(defaultOutput, 0, "Default device should still be valid after multiple teardowns")
    }

    private func getDefaultOutputDeviceID() -> AudioDeviceID {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var deviceID: AudioDeviceID = 0
        var dataSize = UInt32(MemoryLayout<AudioDeviceID>.size)

        AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0, nil,
            &dataSize,
            &deviceID
        )

        return deviceID
    }
}
