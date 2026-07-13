import XCTest
@testable import SoundFlow

final class AudioDeviceTests: XCTestCase {

    // MARK: - AudioDevice Model Tests

    func testAudioDeviceEquality() {
        let device1 = AudioDevice(
            id: 1,
            name: "Test Device",
            manufacturer: "Test Manufacturer",
            isInput: true,
            isOutput: true,
            inputChannelCount: 2,
            outputChannelCount: 2,
            isBuiltIn: false
        )

        let device2 = AudioDevice(
            id: 1,
            name: "Different Name",
            manufacturer: "Different Manufacturer",
            isInput: false,
            isOutput: false,
            inputChannelCount: 0,
            outputChannelCount: 0,
            isBuiltIn: true
        )

        XCTAssertEqual(device1, device2, "Devices with same ID should be equal")
    }

    func testAudioDeviceHashing() {
        let device1 = AudioDevice(
            id: 1,
            name: "Device 1",
            manufacturer: "Manufacturer",
            isInput: true,
            isOutput: true,
            inputChannelCount: 2,
            outputChannelCount: 2,
            isBuiltIn: false
        )

        let device2 = AudioDevice(
            id: 2,
            name: "Device 2",
            manufacturer: "Manufacturer",
            isInput: true,
            isOutput: true,
            inputChannelCount: 2,
            outputChannelCount: 2,
            isBuiltIn: false
        )

        var set = Set<AudioDevice>()
        set.insert(device1)
        set.insert(device2)

        XCTAssertEqual(set.count, 2, "Different devices should have different hashes")
    }

    func testAudioDeviceProperties() {
        let device = AudioDevice(
            id: 42,
            name: "Built-in Microphone",
            manufacturer: "Apple Inc.",
            isInput: true,
            isOutput: false,
            inputChannelCount: 1,
            outputChannelCount: 0,
            isBuiltIn: true
        )

        XCTAssertEqual(device.id, 42)
        XCTAssertEqual(device.name, "Built-in Microphone")
        XCTAssertEqual(device.manufacturer, "Apple Inc.")
        XCTAssertTrue(device.isInput)
        XCTAssertFalse(device.isOutput)
        XCTAssertEqual(device.inputChannelCount, 1)
        XCTAssertEqual(device.outputChannelCount, 0)
        XCTAssertTrue(device.isBuiltIn)
    }
}
