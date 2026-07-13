import Foundation
import CoreAudio
import Combine

class AppState: ObservableObject {
    @Published var configurations: [AudioDeviceID: DeviceConfiguration] = [:]
    @Published var isExpanded: Bool = false
    @Published var selectedOutputDeviceIDs: Set<AudioDeviceID> = []
    @Published var selectedInputDeviceID: AudioDeviceID?

    static let shared = AppState()

    private let userDefaultsKey = "SoundFlow_DeviceConfigurations"
    private let selectedOutputKey = "SoundFlow_SelectedOutputDevices"
    private let selectedInputKey = "SoundFlow_SelectedInputDevice"
    private let hasLaunchedKey = "SoundFlow_HasLaunched"

    var hasLaunched: Bool {
        UserDefaults.standard.bool(forKey: hasLaunchedKey)
    }

    private init() {
        loadConfigurations()
        loadSelectedOutputDevices()
        loadSelectedInputDevice()
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

    func saveSelectedOutputDevices(_ deviceIDs: Set<AudioDeviceID>) {
        selectedOutputDeviceIDs = deviceIDs
        let array = Array(deviceIDs)
        UserDefaults.standard.set(array, forKey: selectedOutputKey)
    }

    func loadSelectedOutputDeviceIDs() -> Set<AudioDeviceID> {
        selectedOutputDeviceIDs
    }

    func saveSelectedInputDevice(_ deviceID: AudioDeviceID?) {
        selectedInputDeviceID = deviceID
        if let id = deviceID {
            UserDefaults.standard.set(id, forKey: selectedInputKey)
        } else {
            UserDefaults.standard.removeObject(forKey: selectedInputKey)
        }
    }

    func markHasLaunched() {
        UserDefaults.standard.set(true, forKey: hasLaunchedKey)
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

    private func loadSelectedOutputDevices() {
        guard let array = UserDefaults.standard.array(forKey: selectedOutputKey) as? [AudioDeviceID] else { return }
        selectedOutputDeviceIDs = Set(array)
    }

    private func loadSelectedInputDevice() {
        let id = UserDefaults.standard.integer(forKey: selectedInputKey)
        if id != 0 {
            selectedInputDeviceID = AudioDeviceID(id)
        }
    }
}
