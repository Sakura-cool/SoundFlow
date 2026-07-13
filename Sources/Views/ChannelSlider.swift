import SwiftUI

struct ChannelSlider: View {
    let label: String
    let icon: String

    @Binding var value: Float
    @Binding var delay: Double

    let onVolumeChange: (Float) -> Void
    let onDelayChange: (Double) -> Void

    var body: some View {
        VStack(spacing: 6) {
            // Volume Control
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

            // Delay Control
            HStack(spacing: 8) {
                Image(systemName: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 16)

                Text("Delay")
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
