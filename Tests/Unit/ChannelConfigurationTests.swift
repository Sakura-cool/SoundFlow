import XCTest
@testable import SoundFlow

final class ChannelConfigurationTests: XCTestCase {

    // MARK: - Default Values

    func testDefaultConfiguration() {
        let config = ChannelConfiguration.default

        XCTAssertEqual(config.leftVolume, 1.0)
        XCTAssertEqual(config.rightVolume, 1.0)
        XCTAssertEqual(config.delayMs, 0.0)
    }

    // MARK: - Codable

    func testChannelConfigurationCodable() throws {
        let config = ChannelConfiguration(
            leftVolume: 0.75,
            rightVolume: 0.5,
            delayMs: 25.0
        )

        let data = try JSONEncoder().encode(config)
        let decoded = try JSONDecoder().decode(ChannelConfiguration.self, from: data)

        XCTAssertEqual(config.leftVolume, decoded.leftVolume)
        XCTAssertEqual(config.rightVolume, decoded.rightVolume)
        XCTAssertEqual(config.delayMs, decoded.delayMs)
    }

    // MARK: - Equality

    func testChannelConfigurationEquality() {
        let config1 = ChannelConfiguration(leftVolume: 0.5, rightVolume: 0.5, delayMs: 10.0)
        let config2 = ChannelConfiguration(leftVolume: 0.5, rightVolume: 0.5, delayMs: 10.0)

        XCTAssertEqual(config1, config2)
    }

    func testChannelConfigurationInequality() {
        let config1 = ChannelConfiguration(leftVolume: 0.5, rightVolume: 0.5, delayMs: 10.0)
        let config2 = ChannelConfiguration(leftVolume: 0.5, rightVolume: 0.5, delayMs: 20.0)

        XCTAssertNotEqual(config1, config2)
    }
}
