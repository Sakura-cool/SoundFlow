import SwiftUI
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover = NSPopover()

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            let config = NSImage.SymbolConfiguration(pointSize: 13, weight: .medium)
            let image = NSImage(systemSymbolName: "speaker.wave.2.fill", accessibilityDescription: "SoundFlow")?
                .withSymbolConfiguration(config)
            button.image = image
            button.target = self
            button.action = #selector(togglePopover)
        }

        let contentView = ContentView()
            .environmentObject(AudioDeviceManager.shared)
            .environmentObject(AppState.shared)

        popover.contentViewController = NSHostingController(rootView: contentView)
        popover.behavior = .transient
        popover.animates = true
    }

    func applicationWillTerminate(_ notification: Notification) {
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
