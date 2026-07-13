import SwiftUI

struct ChannelSlider: View {
    let label: String
    let icon: String

    @Binding var delay: Double
    let onDelayChange: (Double) -> Void

    @Binding var value: Float
    let onVolumeChange: (Float) -> Void

    init(
        label: String,
        icon: String,
        delay: Binding<Double>,
        onDelayChange: @escaping (Double) -> Void
    ) {
        self.label = label
        self.icon = icon
        self._delay = delay
        self.onDelayChange = onDelayChange
        self._value = .constant(0)
        self.onVolumeChange = { _ in }
    }

    init(
        label: String,
        icon: String,
        value: Binding<Float>,
        delay: Binding<Double>,
        onVolumeChange: @escaping (Float) -> Void,
        onDelayChange: @escaping (Double) -> Void
    ) {
        self.label = label
        self.icon = icon
        self._value = value
        self._delay = delay
        self.onVolumeChange = onVolumeChange
        self.onDelayChange = onDelayChange
    }

    var hasVolumeSlider: Bool {
        onVolumeChange({} as! Float) == ()  // always false, just a placeholder
        return true
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 16)

                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 80, alignment: .leading)

                Slider(
                    value: $delay,
                    in: 0...100,
                    step: 1,
                    onEditingChanged: { editing in
                        if !editing {
                            onDelayChange(delay)
                        }
                    }
                )
                .onChange(of: delay) { _, newValue in
                    onDelayChange(newValue)
                }

                Text("\(Int(delay))ms")
                    .font(.caption2.monospacedDigit())
                    .foregroundColor(.secondary)
                    .frame(width: 36, alignment: .trailing)
            }
        }
    }
}

struct VolumeSlider: View {
    let label: String
    let icon: String

    @Binding var value: Float
    let onVolumeChange: (Float) -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 16)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)

            Slider(
                value: $value,
                in: 0...1,
                onEditingChanged: { editing in
                    if !editing {
                        onVolumeChange(value)
                    }
                }
            )
            .onChange(of: value) { _, newValue in
                onVolumeChange(newValue)
            }

            Text("\(Int(value * 100))%")
                .font(.caption2.monospacedDigit())
                .foregroundColor(.secondary)
                .frame(width: 36, alignment: .trailing)
        }
    }
}
