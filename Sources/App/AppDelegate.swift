import SwiftUI
import Combine
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover = NSPopover()
    private let updateManager = UpdateManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let bundleID = Bundle.main.bundleIdentifier ?? "com.soundflow.app"
        let running = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
        if running.count > 1 {
            NSApplication.shared.terminate(nil)
            return
        }

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            let config = NSImage.SymbolConfiguration(pointSize: 13, weight: .medium)
            let image = NSImage(systemSymbolName: "waveform", accessibilityDescription: "SoundFlow")?
                .withSymbolConfiguration(config)
            button.image = image
            button.target = self
            button.action = #selector(togglePopover)
        }

        let contentView = ContentView()
            .environmentObject(AudioDeviceManager.shared)
            .environmentObject(AppState.shared)
            .environmentObject(updateManager)

        popover.contentViewController = NSHostingController(rootView: contentView)
        popover.behavior = .transient
        popover.animates = true

        updateManager.startAutoCheck()
    }

    func applicationWillTerminate(_ notification: Notification) {
        updateManager.stopAutoCheck()
        AudioDeviceManager.shared.teardownAggregateDevice()
    }

    @objc func togglePopover() {
        guard let button = statusItem.button else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
}
