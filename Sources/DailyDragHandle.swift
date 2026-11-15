import AppKit

/// Local-only drag source. Does not export reminder titles or modify reminders.
final class DailyDragHandle: NSView, NSDraggingSource {
    static let pasteboardType = NSPasteboard.PasteboardType("com.tangbonze.edgetodo.daily-order")
    static private(set) var isDragging = false
    var taskID = ""
    var rank = 0
    var count = 0
    var onEnd: (() -> Void)?
    var onMove: ((Int) -> Void)?
    private var pressEvent: NSEvent?
    override var acceptsFirstResponder: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setAccessibilityElement(true)
        setAccessibilityRole(.button)
        toolTip = L10n.t("拖动排序 · 聚焦后按 ↑ / ↓", "Drag to reorder · focus and press ↑ / ↓")
        setAccessibilityCustomActions([
            NSAccessibilityCustomAction(name: L10n.t("提高优先级", "Move up"), target: self, selector: #selector(raisePriority)),
            NSAccessibilityCustomAction(name: L10n.t("降低优先级", "Move down"), target: self, selector: #selector(lowerPriority))
        ])
    }
    required init?(coder: NSCoder) { fatalError() }
    @objc private func raisePriority() -> Bool { guard rank > 0 else { return false }; onMove?(-1); return true }
    @objc private func lowerPriority() -> Bool { guard rank + 1 < count else { return false }; onMove?(1); return true }
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 126 { _ = raisePriority() }
        else if event.keyCode == 125 { _ = lowerPriority() }
        else { super.keyDown(with: event) }
    }
    override func becomeFirstResponder() -> Bool { needsDisplay = true; return true }
    override func resignFirstResponder() -> Bool { needsDisplay = true; return true }
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let text = NSAttributedString(string: "⋮⋮", attributes: [.font: NSFont.systemFont(ofSize: 15, weight: .medium), .foregroundColor: NSColor.secondaryLabelColor])
        text.draw(at: NSPoint(x: 4, y: 3))
        if window?.firstResponder === self {
            NSColor.keyboardFocusIndicatorColor.setStroke()
            let outline = NSBezierPath(roundedRect: bounds.insetBy(dx: 1, dy: 1), xRadius: 4, yRadius: 4)
            outline.lineWidth = 2; outline.stroke()
        }
    }
    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        pressEvent = event
    }
    override func mouseUp(with event: NSEvent) { pressEvent = nil }
    override func mouseDragged(with event: NSEvent) {
        guard let start = pressEvent, !Self.isDragging,
              hypot(event.locationInWindow.x - start.locationInWindow.x, event.locationInWindow.y - start.locationInWindow.y) > 4 else { return }
        pressEvent = nil
        let paste = NSPasteboardItem()
        paste.setString(taskID, forType: Self.pasteboardType)
        let item = NSDraggingItem(pasteboardWriter: paste)
        let image = NSImage(size: NSSize(width: 100, height: 28))
        image.lockFocus()
        NSColor.systemIndigo.withAlphaComponent(0.15).setFill()
        NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: 100, height: 28), xRadius: 7, yRadius: 7).fill()
        (L10n.t("⋮⋮ 移动任务", "⋮⋮ Move task") as NSString).draw(at: NSPoint(x: 8, y: 6), withAttributes: [.font: NSFont.systemFont(ofSize: 12), .foregroundColor: NSColor.labelColor])
        image.unlockFocus()
        item.setDraggingFrame(NSRect(origin: .zero, size: image.size), contents: image)
        Self.isDragging = true
        let session = beginDraggingSession(with: [item], event: event, source: self)
        session.animatesToStartingPositionsOnCancelOrFail = true
    }
    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation { context == .withinApplication ? .move : [] }
    func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        Self.isDragging = false
        // Rebuild after the native session has released its source/destination.
        let callback = onEnd
        DispatchQueue.main.async { callback?() }
    }
}
