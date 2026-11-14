import SwiftUI
import AppKit
@main struct EverydayFightsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    var body: some Scene { Settings { Text("everydayFights · local-first, small steps daily").padding() } }
}
@MainActor final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var status: NSStatusItem!
    private var panel: NSPanel!
    private var handle: NSPanel!
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
        handle = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 26, height: 76), styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        handle.level = .floating
        handle.isOpaque = false; handle.backgroundColor = .clear
        handle.hasShadow = true; handle.hidesOnDeactivate = false
        handle.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        handle.contentView = NSHostingView(rootView: EdgeHandle { [weak self] in self?.toggle() })
        positionHandle()
        handle.orderFrontRegardless()
        NotificationCenter.default.addObserver(self, selector: #selector(positionHandle), name: NSApplication.didChangeScreenParametersNotification, object: nil)
        // Make the first launch discoverable; subsequent dismissal is controlled by the menu-bar button.
        toggle()
    }
    @objc private func positionHandle() {
        guard let frame = NSScreen.main?.visibleFrame else { return }
        handle.setFrameOrigin(NSPoint(x: frame.maxX - 26, y: frame.midY - 38))
    }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !panel.isVisible { toggle() }
        return true
    }
    @objc private func toggle() {
        if panel.isVisible { panel.orderOut(nil); return }
        let frame = (status.button?.window?.screen ?? NSScreen.main)?.visibleFrame ?? .zero
        let height = min(704, frame.height - 16)
        let width = min(380, frame.width - 16)
        panel.setFrame(NSRect(x: frame.maxX - width - 34, y: frame.maxY - height - 8, width: width, height: height), display: false)
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
    }
    func windowDidResignKey(_ notification: Notification) { panel.orderOut(nil) }
    func windowShouldClose(_ sender: NSWindow) -> Bool { panel.orderOut(nil); return false }
}

struct EdgeHandle: View {
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: "chevron.left").font(.system(size: 10, weight: .semibold))
                Capsule().fill(Color.secondary.opacity(0.5)).frame(width: 3, height: 22)
            }
            .frame(width: 26, height: 76)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(.primary.opacity(0.08)))
        }.buttonStyle(.plain).help("Open everydayFights")
            .accessibilityLabel("Open everydayFights side panel")
    }
}
