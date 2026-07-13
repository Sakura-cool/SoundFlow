import SwiftUI

struct OutputDeviceRow: View {
    let device: AudioDevice

    @EnvironmentObject var audioManager: AudioDeviceManager
    @EnvironmentObject var appState: AppState

    @State private var isExpanded = false
    @State private var deviceVolume: Float = 1.0
    @State private var leftVolume: Float = 1.0
    @State private var rightVolume: Float = 1.0
    @State private var delayMs: Double = 0.0

    private var isSelected: Bool {
        audioManager.selectedOutputDevices.contains(device.id)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Button(action: { audioManager.toggleOutputDevice(device) }) {
                    HStack(spacing: 8) {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundColor(isSelected ? .accentColor : .secondary)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(device.name)
                                .font(.system(.body, weight: isSelected ? .semibold : .regular))
                                .foregroundColor(isSelected ? .primary : .secondary)
                                .lineLimit(1)

                            Text(device.manufacturer)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)

                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                }) {
                    HStack(spacing: 4) {
                        Spacer()
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(width: 40)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            if isExpanded {
                channelControls
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(isSelected ? Color.accentColor.opacity(0.05) : Color.clear)
        .onAppear {
            loadConfiguration()
        }
    }

    private var channelControls: some View {
        VStack(spacing: 12) {
            Divider()

            VolumeSlider(
                label: "Volume",
                icon: "speaker.wave.2",
                value: Binding(
                    get: { deviceVolume },
                    set: { newValue in
                        deviceVolume = newValue
                        audioManager.setDeviceVolume(newValue, deviceID: device.id, isOutput: true)
                    }
                ),
                onVolumeChange: { _ in }
            )

            ChannelSlider(
                label: "Delay",
                icon: "clock",
                delay: $delayMs,
                onDelayChange: { delay in
                    appState.setOutputConfiguration(for: device.id, ChannelConfiguration(
                        leftVolume: leftVolume,
                        rightVolume: rightVolume,
                        deviceVolume: deviceVolume,
                        delayMs: delay
                    ))
                }
            )

            panControl
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
    }

    private var panControl: some View {
        VStack(spacing: 4) {
            HStack {
                Text("Balance")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
            }

            HStack {
                Text("L")
                    .font(.caption2)
                    .foregroundColor(.blue)

                Slider(
                    value: Binding(
                        get: { (leftVolume - rightVolume) / 2 + 0.5 },
                        set: { newValue in
                            let pan = (newValue - 0.5) * 2
                            let clampedPan = max(-1.0, min(1.0, pan))
                            let left = clampedPan <= 0 ? 1.0 : 1.0 - clampedPan
                            let right = clampedPan >= 0 ? 1.0 : 1.0 + clampedPan
                            leftVolume = left
                            rightVolume = right
                            appState.setOutputConfiguration(for: device.id, ChannelConfiguration(
                                leftVolume: left,
                                rightVolume: right,
                                deviceVolume: deviceVolume,
                                delayMs: delayMs
                            ))
                            audioManager.applyVolumeToDevice(deviceID: device.id, isOutput: true)
                        }
                    ),
                    in: 0...1
                )

                Text("R")
                    .font(.caption2)
                    .foregroundColor(.red)
            }
        }
    }

    private var deviceIcon: String {
        if device.name.lowercased().contains("headphone") || device.name.lowercased().contains("airpods") {
            return "headphones"
        } else if device.name.lowercased().contains("usb") {
            return "cable.connector"
        } else {
            return "speaker.wave.2.fill"
        }
    }

    private func loadConfiguration() {
        let config = appState.getConfiguration(for: device.id)
        if let outputConfig = config.outputConfig {
            deviceVolume = outputConfig.deviceVolume
            leftVolume = outputConfig.leftVolume
            rightVolume = outputConfig.rightVolume
            delayMs = outputConfig.delayMs
        }
    }
}
