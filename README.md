# SoundFlow

macOS menu bar audio device manager with multi-speaker output support.

## Overview

SoundFlow lives in the menu bar (no Dock icon) and gives you full control over every audio input and output device connected to your Mac. Select multiple output devices simultaneously, adjust volume at three levels (master → per-device → L/R balance), set per-device delays, and create Core Audio aggregate devices on the fly.

## Features

- **Menu bar only** — `LSUIElement` app, no Dock icon, no terminal window
- **Multi-speaker output** — select any number of output devices; SoundFlow creates a Core Audio aggregate device automatically
- **Three-tier volume hierarchy** — master volume constrains per-device volume, which constrains L/R balance
- **Per-device delay** — independent delay compensation per output channel (0–1000 ms)
- **Per-device balance** — L/R balance slider per device
- **Input device support** — select and control microphone input with the same volume/balance/delay controls
- **Device hotplug** — automatically detects device connect/disconnect
- **Persistent configuration** — all settings saved to `UserDefaults` and restored across launches
- **Universal binary** — arm64 + x86_64

## Requirements

- macOS 14.0+
- Xcode 15+ (for building)
- Swift 5.9+

## Building

### Universal binary (.app bundle)

```bash
bash scripts/build_app.sh
```

Output: `.build/release/SoundFlow.app`

### Manual build

```bash
swift build -c release --arch arm64 --arch x86_64
```

## Testing

All code changes must include unit tests. Run tests before committing:

```bash
swift test
```

### Test Requirements

1. **Coverage**: Every new feature or bug fix must include corresponding unit tests
2. **Edge cases**: Test boundary conditions, empty states, and error paths
3. **Isolation**: Tests must not depend on external state or other tests
4. **Assertions**: Each test must have at least one meaningful assertion

### Test Structure

```
Tests/
├── Unit/
│   ├── AudioDeviceTests.swift
│   ├── AudioDeviceManagerTests.swift
│   ├── AppStateTests.swift
│   ├── ChannelConfigurationTests.swift
│   ├── DeviceConfigurationTests.swift
│   ├── CrashDiagnosisTests.swift
│   └── MultiOutputTests.swift
└── Integration/
    └── CoreAudioIntegrationTests.swift
```

## Architecture

```
Sources/
├── App/
│   └── AppDelegate.swift          # NSStatusItem, NSPopover, lifecycle
├── Core/
│   ├── AudioDeviceManager.swift   # Core Audio device enumeration, volume, aggregate devices
│   └── AppState.swift             # UserDefaults persistence
├── Models/
│   └── AudioDevice.swift          # AudioDevice, ChannelConfiguration, DeviceConfiguration
└── Views/
    ├── ContentView.swift          # Master volume, device list, tab selector
    ├── OutputDeviceRow.swift      # Per-output-device controls (split-row layout)
    ├── InputDeviceRow.swift       # Per-input-device controls (split-row layout)
    └── ChannelSlider.swift        # Delay slider + VolumeSlider component
```

### Volume Hierarchy

```
Master Volume × Device Volume × Balance Ratio = Actual Hardware Volume
```

- **Master volume** (0–100%): global multiplier applied to all devices
- **Device volume** (0–100%): per-device multiplier stored in `ChannelConfiguration`
- **Balance ratio** (L/R): derived from the balance slider position

### Aggregate Devices

When multiple output devices are selected, SoundFlow creates a Core Audio aggregate device that combines them. The aggregate device is torn down when fewer than two devices are selected, or on app termination.

## Configuration

All settings persist via `UserDefaults` (suite: `com.soundflow.app`):

- `selectedOutputDeviceIDs` — set of selected output device IDs
- `selectedInputDeviceID` — selected input device ID
- `masterVolume` / `inputMasterVolume` — global volume levels
- Per-device `DeviceConfiguration` — device name, active state, L/R volume, device volume, delay

## License

MIT
