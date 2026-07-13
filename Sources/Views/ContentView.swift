import SwiftUI

struct ContentView: View {
    @EnvironmentObject var audioManager: AudioDeviceManager
    @EnvironmentObject var appState: AppState

    @State private var selectedTab: DeviceTab = .output

    enum DeviceTab: String {
        case output = "Output"
        case input = "Input"
    }

    var body: some View {
        VStack(spacing: 0) {
            headerView
            tabSelector
            deviceListView
            Divider()
            footerView
        }
        .frame(width: 320, height: 400)
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Image(systemName: "waveform")
                .font(.title2)
                .foregroundColor(.accentColor)

            Text("SoundFlow")
                .font(.headline)

            Spacer()

            Button(action: { audioManager.refreshDeviceList() }) {
                Image(systemName: "arrow.clockwise")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .help("Refresh devices")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach([DeviceTab.output, DeviceTab.input], id: \.self) { tab in
                Button(action: { selectedTab = tab }) {
                    VStack(spacing: 4) {
                        Image(systemName: tab == .output ? "speaker.wave.2.fill" : "mic.fill")
                            .font(.caption)

                        Text(tab.rawValue)
                            .font(.caption2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                    .background(selectedTab == tab ? Color.accentColor.opacity(0.2) : Color.clear)
                    .foregroundColor(selectedTab == tab ? .accentColor : .secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }

    // MARK: - Device List

    private var deviceListView: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                if selectedTab == .output {
                    ForEach(audioManager.outputDevices) { device in
                        OutputDeviceRow(device: device)
                    }
                } else {
                    ForEach(audioManager.inputDevices) { device in
                        InputDeviceRow(device: device)
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: - Footer

    private var footerView: some View {
        HStack {
            Circle()
                .fill(.green)
                .frame(width: 8, height: 8)

            Text("\(audioManager.outputDevices.count) output, \(audioManager.inputDevices.count) input")
                .font(.caption2)
                .foregroundColor(.secondary)

            Spacer()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor))
    }
}
