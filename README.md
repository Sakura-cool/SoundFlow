# SoundFlow

[English](README-en.md)

macOS 菜单栏音频设备管理器，支持多扬声器输出。

## 概述

SoundFlow 驻留在菜单栏中（无 Dock 图标），让你完全掌控 Mac 连接的所有音频输入和输出设备。可同时选择多个输出设备，按三个层级调节音量（主音量 → 设备音量 → 左右声道平衡），为每个设备设置独立延迟，并可即时创建 Core Audio 聚合设备。

## 功能特性

- **仅菜单栏运行** — `LSUIElement` 应用，无 Dock 图标，无终端窗口
- **多扬声器输出** — 任意选择多个输出设备，SoundFlow 自动创建 Core Audio 聚合设备
- **三级音量层级** — 主音量约束设备音量，设备音量约束左右声道平衡
- **设备独立延迟** — 每个输出通道独立延迟补偿（0–1000 毫秒）
- **设备独立平衡** — 每个设备独立的左右声道平衡滑块
- **输入设备支持** — 选择和控制麦克风输入，具备与输出相同的音量/平衡/延迟控制
- **设备热插拔** — 自动检测设备连接和断开
- **配置持久化** — 所有设置保存至 `UserDefaults`，重启后自动恢复
- **通用二进制** — 支持 arm64 + x86_64

## 系统要求

- macOS 14.0+
- Xcode 15+（用于构建）
- Swift 5.9+

## 构建

### 通用二进制（.app 包）

```bash
bash scripts/build_app.sh
```

输出路径：`.build/release/SoundFlow.app`

### 手动构建

```bash
swift build -c release --arch arm64 --arch x86_64
```

## 测试

所有代码变更必须包含单元测试。提交前请运行测试：

```bash
swift test
```

### 测试要求

1. **覆盖率**：每个新功能或 bug 修复必须包含对应的单元测试
2. **边界情况**：测试边界条件、空状态和错误路径
3. **隔离性**：测试不得依赖外部状态或其他测试
4. **断言**：每个测试必须至少包含一个有意义的断言

### 测试结构

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

## 项目架构

```
Sources/
├── App/
│   └── AppDelegate.swift          # NSStatusItem、NSPopover、生命周期管理
├── Core/
│   ├── AudioDeviceManager.swift   # Core Audio 设备枚举、音量控制、聚合设备
│   └── AppState.swift             # UserDefaults 持久化
├── Models/
│   └── AudioDevice.swift          # AudioDevice、ChannelConfiguration、DeviceConfiguration
└── Views/
    ├── ContentView.swift          # 主音量、设备列表、标签页切换
    ├── OutputDeviceRow.swift      # 输出设备控件（分栏布局）
    ├── InputDeviceRow.swift       # 输入设备控件（分栏布局）
    └── ChannelSlider.swift        # 延迟滑块 + 音量滑块组件
```

### 音量层级

```
主音量 × 设备音量 × 平衡比例 = 实际硬件音量
```

- **主音量**（0–100%）：应用于所有设备的全局乘数
- **设备音量**（0–100%）：存储在 `ChannelConfiguration` 中的单设备乘数
- **平衡比例**（左/右）：由平衡滑块位置计算得出

### 聚合设备

当选择多个输出设备时，SoundFlow 会创建一个 Core Audio 聚合设备将它们组合。当选择的设备少于两个或应用终止时，聚合设备会被自动拆除。

## 配置

所有设置通过 `UserDefaults`（套件名：`com.soundflow.app`）持久化：

- `selectedOutputDeviceIDs` — 已选输出设备 ID 集合
- `selectedInputDeviceID` — 已选输入设备 ID
- `masterVolume` / `inputMasterVolume` — 全局音量级别
- 每设备 `DeviceConfiguration` — 设备名称、激活状态、左右声道音量、设备音量、延迟

## 许可证

MIT
