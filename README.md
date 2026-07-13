# SoundFlow

macOS menu bar audio device manager with multi-speaker output support.

## Features

- Menu bar app (LSUIElement)
- Per-channel volume/delay/balance control
- Multi-speaker output via Core Audio aggregate devices
- Device hotplug detection
- Configuration persistence

## Building

```bash
swift build -c release --arch arm64 --arch x86_64
bash scripts/build_app.sh
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
│   ├── AudioDeviceTests.swift        # Model tests
│   ├── ChannelConfigurationTests.swift
│   ├── DeviceConfigurationTests.swift
│   └── AppStateTests.swift           # State management
└── Integration/
    ├── AudioDeviceManagerTests.swift  # Core Audio integration
    └── CoreAudioTests.swift           # Low-level API tests
```
