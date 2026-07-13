import XCTest
import CoreAudio
@testable import SoundFlow

final class CoreAudioIntegrationTests: XCTestCase {

    // MARK: - System Object Access

    func testSystemObjectAccessible() {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var dataSize: UInt32 = 0
        let status = AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0, nil,
            &dataSize
        )

        XCTAssertEqual(status, noErr, "Should be able to access system object")
        XCTAssertTrue(dataSize > 0, "Should have at least one device")
    }

    // MARK: - Default Device Access

    func testGetDefaultOutputDevice() {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var deviceID: AudioDeviceID = 0
        var dataSize = UInt32(MemoryLayout<AudioDeviceID>.size)

        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0, nil,
            &dataSize,
            &deviceID
        )

        XCTAssertEqual(status, noErr, "Should be able to get default output device")
        XCTAssertTrue(deviceID > 0, "Default output device ID should be valid")
    }

    func testGetDefaultInputDevice() {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var deviceID: AudioDeviceID = 0
        var dataSize = UInt32(MemoryLayout<AudioDeviceID>.size)

        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0, nil,
            &dataSize,
            &deviceID
        )

        XCTAssertEqual(status, noErr, "Should be able to get default input device")
        XCTAssertTrue(deviceID > 0, "Default input device ID should be valid")
    }

    // MARK: - Device Properties

    func testGetDeviceName() {
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

        var namePropertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceNameCFString,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var name: CFString?
        var nameSize = UInt32(MemoryLayout<CFString>.size)

        let status = AudioObjectGetPropertyData(
            deviceID,
            &namePropertyAddress,
            0, nil,
            &nameSize,
            &name
        )

        XCTAssertEqual(status, noErr, "Should be able to get device name")
        XCTAssertNotNil(name, "Device name should not be nil")
        XCTAssertFalse((name as String?)?.isEmpty ?? true, "Device name should not be empty")
    }

    // MARK: - Volume Properties

    func testGetVolumeProperty() {
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

        var volumePropertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: 0
        )

        guard AudioObjectHasProperty(deviceID, &volumePropertyAddress) else {
            return
        }

        var volume: Float32 = 0.0
        var volumeSize = UInt32(MemoryLayout<Float32>.size)

        let status = AudioObjectGetPropertyData(
            deviceID,
            &volumePropertyAddress,
            0, nil,
            &volumeSize,
            &volume
        )

        XCTAssertEqual(status, noErr, "Should be able to get volume")
        XCTAssertTrue(volume >= 0.0 && volume <= 1.0, "Volume should be between 0 and 1")
    }
}
