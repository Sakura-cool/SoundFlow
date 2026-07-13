import Foundation
import CoreAudio
import AVFoundation

// MARK: - Audio Device Model

struct AudioDevice: Identifiable, Hashable {
    let id: AudioDeviceID
    let name: String
    let manufacturer: String
    let isInput: Bool
    let isOutput: Bool
    let inputChannelCount: Int
    let outputChannelCount: Int
    let isBuiltIn: Bool

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: AudioDevice, rhs: AudioDevice) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Channel Configuration

struct ChannelConfiguration: Codable, Equatable {
    var leftVolume: Float    // 0.0 - 1.0
    var rightVolume: Float   // 0.0 - 1.0
    var delayMs: Double      // Delay in milliseconds

    static let `default` = ChannelConfiguration(
        leftVolume: 1.0,
        rightVolume: 1.0,
        delayMs: 0.0
    )
}

// MARK: - Device Configuration

struct DeviceConfiguration: Codable, Equatable {
    var deviceId: AudioDeviceID
    var deviceName: String
    var outputConfig: ChannelConfiguration?
    var inputConfig: ChannelConfiguration?
    var isActive: Bool
}
