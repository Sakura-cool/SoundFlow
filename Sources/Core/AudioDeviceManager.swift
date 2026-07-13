import Foundation
import CoreAudio
import Combine

class AudioDeviceManager: ObservableObject {
    @Published var outputDevices: [AudioDevice] = []
    @Published var inputDevices: [AudioDevice] = []
    @Published var selectedOutputDevices: Set<AudioDeviceID> = []
    @Published var selectedInputDevice: AudioDevice?

    static let shared = AudioDeviceManager()

    private var deviceListenerBlock: AudioObjectPropertyListenerBlock?
    private let deviceListChangedNotification = Notification.Name("AudioDeviceListChanged")
    private var aggregateDeviceID: AudioDeviceID = 0

    private init() {
        refreshDeviceList()
        startDeviceListener()
    }

    deinit {
        stopDeviceListener()
    }

    // MARK: - Device Enumeration

    func refreshDeviceList() {
        outputDevices = getDevices(isInput: false)
        inputDevices = getDevices(isInput: true)
        updateSelectedDevices()
    }

    private func getDevices(isInput: Bool) -> [AudioDevice] {
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

        guard status == noErr else { return [] }

        let deviceCount = Int(dataSize) / MemoryLayout<AudioDeviceID>.size
        var deviceIDs = [AudioDeviceID](repeating: 0, count: deviceCount)

        let status2 = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0, nil,
            &dataSize,
            &deviceIDs
        )

        guard status2 == noErr else { return [] }

        var devices: [AudioDevice] = []

        for deviceID in deviceIDs {
            guard let device = createAudioDevice(id: deviceID) else { continue }

            if isInput && device.inputChannelCount > 0 {
                devices.append(device)
            } else if !isInput && device.outputChannelCount > 0 {
                devices.append(device)
            }
        }

        return devices
    }

    private func createAudioDevice(id: AudioDeviceID) -> AudioDevice? {
        if id == aggregateDeviceID { return nil }

        let name = getDeviceName(id: id) ?? "Unknown Device"
        if name == "SoundFlow Aggregate" { return nil }

        let manufacturer = getDeviceManufacturer(id: id) ?? "Unknown"
        let inputChannels = getChannelCount(id: id, isInput: true)
        let outputChannels = getChannelCount(id: id, isInput: false)
        let isBuiltIn = getIsBuiltIn(id: id)

        return AudioDevice(
            id: id,
            name: name,
            manufacturer: manufacturer,
            isInput: inputChannels > 0,
            isOutput: outputChannels > 0,
            inputChannelCount: inputChannels,
            outputChannelCount: outputChannels,
            isBuiltIn: isBuiltIn
        )
    }

    private func getDeviceName(id: AudioDeviceID) -> String? {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceNameCFString,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var name: CFString?
        var dataSize = UInt32(MemoryLayout<CFString>.size)

        let status = AudioObjectGetPropertyData(
            id,
            &propertyAddress,
            0, nil,
            &dataSize,
            &name
        )

        return status == noErr ? name as String? : nil
    }

    private func getDeviceManufacturer(id: AudioDeviceID) -> String? {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceManufacturerCFString,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var manufacturer: CFString?
        var dataSize = UInt32(MemoryLayout<CFString>.size)

        let status = AudioObjectGetPropertyData(
            id,
            &propertyAddress,
            0, nil,
            &dataSize,
            &manufacturer
        )

        return status == noErr ? manufacturer as String? : nil
    }

    private func getChannelCount(id: AudioDeviceID, isInput: Bool) -> Int {
        let scope: AudioObjectPropertyScope = isInput ? kAudioDevicePropertyScopeInput : kAudioDevicePropertyScopeOutput

        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreamConfiguration,
            mScope: scope,
            mElement: kAudioObjectPropertyElementMain
        )

        var dataSize: UInt32 = 0
        var status = AudioObjectGetPropertyDataSize(
            id,
            &propertyAddress,
            0, nil,
            &dataSize
        )

        guard status == noErr, dataSize > 0 else { return 0 }

        let bufferListPointer = UnsafeMutableRawPointer.allocate(byteCount: Int(dataSize), alignment: MemoryLayout<AudioBufferList>.alignment)
        defer { bufferListPointer.deallocate() }

        status = AudioObjectGetPropertyData(
            id,
            &propertyAddress,
            0, nil,
            &dataSize,
            bufferListPointer
        )

        guard status == noErr else { return 0 }

        let buffers = UnsafeMutableAudioBufferListPointer(bufferListPointer.bindMemory(to: AudioBufferList.self, capacity: 1))

        var channelCount = 0
        for buffer in buffers {
            channelCount += Int(buffer.mNumberChannels)
        }

        return channelCount
    }

    private func getIsBuiltIn(id: AudioDeviceID) -> Bool {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyTransportType,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var transportType: UInt32 = 0
        var dataSize = UInt32(MemoryLayout<UInt32>.size)

        let status = AudioObjectGetPropertyData(
            id,
            &propertyAddress,
            0, nil,
            &dataSize,
            &transportType
        )

        guard status == noErr else { return false }

        // kAudioDevicePropertyTransportTypeBuiltIn = 'bltn' = 0x626C746E
        return transportType == 0x626C746E
    }

    // MARK: - Device Selection

    func toggleOutputDevice(_ device: AudioDevice) {
        if selectedOutputDevices.contains(device.id) {
            guard selectedOutputDevices.count > 1 else { return }
            selectedOutputDevices.remove(device.id)
        } else {
            selectedOutputDevices.insert(device.id)
        }
        updateAggregateDevice()
        AppState.shared.saveSelectedOutputDevices(selectedOutputDevices)
    }

    func selectInputDevice(_ device: AudioDevice) {
        selectedInputDevice = device
        setDefaultInputDevice(device.id)
        AppState.shared.saveSelectedInputDevice(device.id)
    }

    private func updateSelectedDevices() {
        restoreSavedOutputSelection()
        restoreSavedInputSelection()
        enforceMinimumSelection()
        syncSystemDefaults()
        restoreAggregateDeviceIfNeeded()
    }

    private func restoreSavedOutputSelection() {
        let savedOutputIDs = AppState.shared.loadSelectedOutputDeviceIDs()
        guard !savedOutputIDs.isEmpty else { return }
        let validIDs = savedOutputIDs.filter { id in outputDevices.contains { $0.id == id } }
        selectedOutputDevices = Set(validIDs)
    }

    private func restoreSavedInputSelection() {
        guard let savedInputID = AppState.shared.selectedInputDeviceID else { return }
        selectedInputDevice = inputDevices.first { $0.id == savedInputID }
    }

    private func enforceMinimumSelection() {
        if selectedOutputDevices.isEmpty && !outputDevices.isEmpty {
            selectedOutputDevices = [outputDevices[0].id]
        }
        if selectedInputDevice == nil && !inputDevices.isEmpty {
            selectedInputDevice = inputDevices[0]
        }
    }

    private func syncSystemDefaults() {
        if let singleID = selectedOutputDevices.first, selectedOutputDevices.count == 1 {
            setDefaultOutputDevice(singleID)
        }
        if let input = selectedInputDevice {
            setDefaultInputDevice(input.id)
        }
    }

    private func restoreAggregateDeviceIfNeeded() {
        guard selectedOutputDevices.count > 1 else { return }
        updateAggregateDevice()
    }

    // MARK: - Aggregate Device

    func updateAggregateDevice() {
        if selectedOutputDevices.count <= 1 {
            teardownAggregateDevice()
            if let singleID = selectedOutputDevices.first {
                setDefaultOutputDevice(singleID)
            }
            return
        }

        let deviceIDs = Array(selectedOutputDevices).sorted()
        if aggregateDeviceID != 0, deviceIDs == getAggregateSubDevices(deviceID: aggregateDeviceID) {
            setDefaultOutputDevice(aggregateDeviceID)
            return
        }

        teardownAggregateDevice()

        guard let newID = createAggregateDevice(name: "SoundFlow Aggregate", subDeviceIDs: deviceIDs) else {
            return
        }

        aggregateDeviceID = newID
        setDefaultOutputDevice(newID)
    }

    private func createAggregateDevice(name: String, subDeviceIDs: [AudioDeviceID]) -> AudioDeviceID? {
        var aggregateID: AudioDeviceID = 0

        let desc: [String: Any] = [
            kAudioAggregateDeviceNameKey as String: name,
            kAudioAggregateDeviceUIDKey as String: "com.soundflow.aggregate.\(UUID().uuidString)",
            kAudioAggregateDeviceSubDeviceListKey as String: subDeviceIDs.map { id -> [String: Any] in
                [
                    kAudioSubDeviceUIDKey as String: getDeviceUID(id: id) ?? "unknown-\(id)"
                ]
            },
            kAudioAggregateDeviceTapListKey as String: [Any](),
            kAudioAggregateDeviceIsPrivateKey as String: false
        ]

        let status = AudioHardwareCreateAggregateDevice(desc as CFDictionary, &aggregateID)

        guard status == noErr else {
            print("Failed to create aggregate device: \(status)")
            return nil
        }

        return aggregateID
    }

    func teardownAggregateDevice() {
        guard aggregateDeviceID != 0 else { return }
        AudioHardwareDestroyAggregateDevice(aggregateDeviceID)
        aggregateDeviceID = 0
    }

    private func getAggregateSubDevices(deviceID: AudioDeviceID) -> [AudioDeviceID] {
        var propertyAddress = AudioObjectPropertyAddress(
            // kAudioAggregateDevicePropertySubDeviceList = 'sdev' = 0x73646576
            mSelector: 0x73646576,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var dataSize: UInt32 = 0
        let status = AudioObjectGetPropertyDataSize(
            deviceID,
            &propertyAddress,
            0, nil,
            &dataSize
        )

        guard status == noErr, dataSize > 0 else { return [] }

        let count = Int(dataSize) / MemoryLayout<AudioDeviceID>.size
        var ids = [AudioDeviceID](repeating: 0, count: count)

        AudioObjectGetPropertyData(
            deviceID,
            &propertyAddress,
            0, nil,
            &dataSize,
            &ids
        )

        return ids
    }

    private func getDeviceUID(id: AudioDeviceID) -> String? {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceUID,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var uid: CFString?
        var dataSize = UInt32(MemoryLayout<CFString>.size)

        let status = AudioObjectGetPropertyData(
            id,
            &propertyAddress,
            0, nil,
            &dataSize,
            &uid
        )

        return status == noErr ? uid as String? : nil
    }

    // MARK: - Default Device Management

    private func getDefaultOutputDevice() -> AudioDeviceID {
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

    private func getDefaultInputDevice() -> AudioDeviceID {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
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

    private func setDefaultOutputDevice(_ deviceID: AudioDeviceID) {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var newDeviceID = deviceID
        AudioObjectSetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0, nil,
            UInt32(MemoryLayout<AudioDeviceID>.size),
            &newDeviceID
        )
    }

    private func setDefaultInputDevice(_ deviceID: AudioDeviceID) {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var newDeviceID = deviceID
        AudioObjectSetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0, nil,
            UInt32(MemoryLayout<AudioDeviceID>.size),
            &newDeviceID
        )
    }

    // MARK: - Volume Control

    func getVolume(deviceID: AudioDeviceID, channel: UInt32, isOutput: Bool) -> Float {
        let scope: AudioObjectPropertyScope = isOutput ? kAudioDevicePropertyScopeOutput : kAudioDevicePropertyScopeInput

        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: scope,
            mElement: channel
        )

        var volume: Float32 = 0.0
        var dataSize = UInt32(MemoryLayout<Float32>.size)

        AudioObjectGetPropertyData(
            deviceID,
            &propertyAddress,
            0, nil,
            &dataSize,
            &volume
        )

        return volume
    }

    func setVolume(_ volume: Float, deviceID: AudioDeviceID, channel: UInt32, isOutput: Bool) {
        let scope: AudioObjectPropertyScope = isOutput ? kAudioDevicePropertyScopeOutput : kAudioDevicePropertyScopeInput

        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: scope,
            mElement: channel
        )

        var newVolume = max(0.0, min(1.0, volume))
        AudioObjectSetPropertyData(
            deviceID,
            &propertyAddress,
            0, nil,
            UInt32(MemoryLayout<Float32>.size),
            &newVolume
        )
    }

    // MARK: - Pan (Left/Right Balance)

    func getPan(deviceID: AudioDeviceID, isOutput: Bool) -> Float {
        let scope: AudioObjectPropertyScope = isOutput ? kAudioDevicePropertyScopeOutput : kAudioDevicePropertyScopeInput

        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStereoPan,
            mScope: scope,
            mElement: kAudioObjectPropertyElementMain
        )

        var pan: Float32 = 0.0
        var dataSize = UInt32(MemoryLayout<Float32>.size)

        AudioObjectGetPropertyData(
            deviceID,
            &propertyAddress,
            0, nil,
            &dataSize,
            &pan
        )

        return pan
    }

    func setPan(_ pan: Float, deviceID: AudioDeviceID, isOutput: Bool) {
        let scope: AudioObjectPropertyScope = isOutput ? kAudioDevicePropertyScopeOutput : kAudioDevicePropertyScopeInput

        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStereoPan,
            mScope: scope,
            mElement: kAudioObjectPropertyElementMain
        )

        var newPan = max(-1.0, min(1.0, pan))
        AudioObjectSetPropertyData(
            deviceID,
            &propertyAddress,
            0, nil,
            UInt32(MemoryLayout<Float32>.size),
            &newPan
        )
    }

    // MARK: - Device Listener

    private func startDeviceListener() {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        deviceListenerBlock = { _, _ in
            DispatchQueue.main.async {
                self.refreshDeviceList()
                NotificationCenter.default.post(name: self.deviceListChangedNotification, object: nil)
            }
        }

        guard let block = deviceListenerBlock else { return }

        AudioObjectAddPropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            DispatchQueue.main,
            block
        )
    }

    private func stopDeviceListener() {
        guard let block = deviceListenerBlock else { return }

        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        AudioObjectRemovePropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            DispatchQueue.main,
            block
        )
    }
}
