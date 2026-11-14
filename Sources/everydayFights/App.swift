import SwiftUI
import AppKit
@main struct EverydayFightsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    var body: some Scene { Settings { Text("everydayFights · local-first, small steps daily").padding() } }
}
@MainActor final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var status: NSStatusItem!
    private var panel: NSPanel!
    private let store = Store()
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        status = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        status.button?.title = "✓"
        status.button?.toolTip = "everydayFights"
        status.button?.target = self; status.button?.action = #selector(toggle)
        panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 380, height: 680), styleMask: [.titled, .closable, .utilityWindow], backing: .buffered, defer: false)
        panel.title = "everydayFights"; panel.isReleasedWhenClosed = false
        panel.level = .floating; panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        panel.delegate = self
        panel.contentView = NSHostingView(rootView: ContentView(store: store))
    }
    @objc private func toggle() {
        if panel.isVisible { panel.orderOut(nil); return }
        let frame = (status.button?.window?.screen ?? NSScreen.main)?.visibleFrame ?? .zero
        panel.setFrameOrigin(NSPoint(x: frame.maxX - 392, y: frame.maxY - 692))
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
    }
    func windowDidResignKey(_ notification: Notification) { panel.orderOut(nil) }
    func windowShouldClose(_ sender: NSWindow) -> Bool { panel.orderOut(nil); return false }
}
