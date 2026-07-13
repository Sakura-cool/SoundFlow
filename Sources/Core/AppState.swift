import Foundation
import CoreAudio
import Combine

class AppState: ObservableObject {
    @Published var configurations: [AudioDeviceID: DeviceConfiguration] = [:]
    @Published var isExpanded: Bool = false

    static let shared = AppState()

    private let userDefaultsKey = "SoundFlow_DeviceConfigurations"

    private init() {
        loadConfigurations()
    }

    // MARK: - Configuration Management

    func getConfiguration(for deviceId: AudioDeviceID) -> DeviceConfiguration {
        if let config = configurations[deviceId] {
            return config
        }

        let defaultConfig = DeviceConfiguration(
            deviceId: deviceId,
            deviceName: "",
            outputConfig: .default,
            inputConfig: .default,
            isActive: true
        )

        configurations[deviceId] = defaultConfig
        return defaultConfig
    }

    func updateConfiguration(for deviceId: AudioDeviceID, _ update: (inout DeviceConfiguration) -> Void) {
        var config = getConfiguration(for: deviceId)
        update(&config)
        configurations[deviceId] = config
        saveConfigurations()
    }

    func setOutputConfiguration(for deviceId: AudioDeviceID, _ config: ChannelConfiguration) {
        updateConfiguration(for: deviceId) { $0.outputConfig = config }
    }

    func setInputConfiguration(for deviceId: AudioDeviceID, _ config: ChannelConfiguration) {
        updateConfiguration(for: deviceId) { $0.inputConfig = config }
    }

    // MARK: - Persistence

    func saveConfigurations() {
        do {
            let data = try JSONEncoder().encode(configurations)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            print("Failed to save configurations: \(error)")
        }
    }

    private func loadConfigurations() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else { return }

        do {
            configurations = try JSONDecoder().decode([AudioDeviceID: DeviceConfiguration].self, from: data)
        } catch {
            print("Failed to load configurations: \(error)")
            configurations = [:]
        }
    }
}
