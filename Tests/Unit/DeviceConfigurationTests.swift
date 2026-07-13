import XCTest
@testable import SoundFlow

final class DeviceConfigurationTests: XCTestCase {

    // MARK: - Codable

    func testDeviceConfigurationCodable() throws {
        let config = DeviceConfiguration(
            deviceId: 123,
            deviceName: "Test Speaker",
            outputConfig: ChannelConfiguration(leftVolume: 0.8, rightVolume: 0.8, delayMs: 5.0),
            inputConfig: ChannelConfiguration(leftVolume: 1.0, rightVolume: 1.0, delayMs: 0.0),
            isActive: true
        )

        let data = try JSONEncoder().encode(config)
        let decoded = try JSONDecoder().decode(DeviceConfiguration.self, from: data)

        XCTAssertEqual(config.deviceId, decoded.deviceId)
        XCTAssertEqual(config.deviceName, decoded.deviceName)
        XCTAssertEqual(config.isActive, decoded.isActive)
        XCTAssertEqual(config.outputConfig, decoded.outputConfig)
        XCTAssertEqual(config.inputConfig, decoded.inputConfig)
    }

    // MARK: - Equality

    func testDeviceConfigurationEquality() {
        let config1 = DeviceConfiguration(
            deviceId: 1,
            deviceName: "Device",
            outputConfig: .default,
            inputConfig: nil,
            isActive: true
        )

        let config2 = DeviceConfiguration(
            deviceId: 1,
            deviceName: "Device",
            outputConfig: .default,
            inputConfig: nil,
            isActive: true
        )

        XCTAssertEqual(config1, config2)
    }

    func testDeviceConfigurationWithDifferentIds() {
        let config1 = DeviceConfiguration(
            deviceId: 1,
            deviceName: "Device",
            outputConfig: nil,
            inputConfig: nil,
            isActive: true
        )

        let config2 = DeviceConfiguration(
            deviceId: 2,
            deviceName: "Device",
            outputConfig: nil,
            inputConfig: nil,
            isActive: true
        )

        XCTAssertNotEqual(config1, config2)
    }
}
