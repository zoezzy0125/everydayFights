import AppKit
import EventKit
@main struct RowMenuTest {
 static func main() {
    _ = NSApplication.shared
    // Never instantiate TodoStore.shared. All UI receives unsaved synthetic data.
    let ek = EKEventStore()
    let root = EKReminder(eventStore: ek); root.title = "Synthetic goal"
    let child = EKReminder(eventStore: ek); child.title = "Synthetic paper"
    let leaf = EKReminder(eventStore: ek); leaf.title = "Synthetic daily"
    let r = TodoItem(reminder: root), c = TodoItem(reminder: child), l = TodoItem(reminder: leaf)
    assert(Set([r.id,c.id,l.id]).count == 3)
    child.notes = "EdgeTodo-Parent: " + r.id
    leaf.notes = "EdgeTodo-Parent: " + c.id + "\nEdgeTodo-Section: daily"
    let done = EKReminder(eventStore: ek); done.title = "Completed goal"; done.isCompleted = true
    let daily = EKReminder(eventStore: ek); daily.title = "Other daily"; daily.notes = "EdgeTodo-Section: daily"
    let d = TodoItem(reminder: done), a = TodoItem(reminder: daily)
    let all = [r,c,l,d,a], tree = TaskHierarchy(nodes: all.map(\.treeNode))
    let rootView = TodoRowView(item:r,hierarchy:tree,availableTasks:all,lists:[])
    let leafView = TodoRowView(item:l,indent:2,parentPath:"Synthetic goal › Synthetic paper",hierarchy:tree,availableTasks:all,lists:[])
    func item(_ view: TodoRowView, _ action: String) -> NSMenuItem { view.menu!.items.first { $0.action.map(NSStringFromSelector) == action }! }
    assert(item(rootView,"addSubtask").isEnabled)
    assert(item(rootView,"addDaily").isEnabled)
    assert(!item(leafView,"addSubtask").isEnabled)
    assert(!item(leafView,"addDaily").isEnabled)
    assert(!item(rootView,"unlinkParent").isEnabled)
    assert(item(leafView,"unlinkParent").isEnabled)
    assert(item(rootView,"showDailyHistory").target != nil)
    let link = leafView.menu!.items.compactMap(\.submenu).first { $0.items.contains { $0.action.map(NSStringFromSelector) == "linkParent:" } }!
    assert(link.items.filter { $0.action.map(NSStringFromSelector) == "linkParent:" }.count == 2)
    assert(link.items.contains { ($0.representedObject as? String) == c.id && $0.state == .on })
    assert(!link.items.contains { ($0.representedObject as? String) == d.id })
    assert(!link.items.contains { ($0.representedObject as? String) == a.id })
    assert(done.isCompleted && daily.notes == "EdgeTodo-Section: daily")
    // Off-screen layout validation only: no window shown, screenshots or mouse input.
    leafView.frame = NSRect(x:0,y:0,width:360,height:85)
    leafView.layoutSubtreeIfNeeded()
    assert(leafView.subviews.contains { ($0 as? NSTextField)?.stringValue == "↳ Synthetic goal › Synthetic paper" })
    assert(leafView.subviews.allSatisfy { $0.frame.origin.x.isFinite && $0.frame.origin.y.isFinite })
    let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
    daily.dueDateComponents = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute], from: yesterday)
    let overdueItem = TodoItem(reminder: daily)
    let overdueRow = TodoRowView(item:overdueItem,hierarchy:tree,availableTasks:all,lists:[])
    let labels = overdueRow.subviews.compactMap { $0 as? NSTextField }
    let signedLabel = labels.first { $0.stringValue.contains("-1") }!
    assert(signedLabel.textColor == .systemRed)
    assert(labels.first { $0.stringValue.contains("Other daily") }!.textColor == .systemRed)
    daily.isCompleted = true
    let completedRow = TodoRowView(item:TodoItem(reminder:daily),hierarchy:tree,availableTasks:all,lists:[])
    assert(!completedRow.subviews.compactMap { $0 as? NSTextField }.contains { $0.stringValue.contains("-1") })
    let trashButtons = rootView.subviews.compactMap { $0 as? NSButton }.filter { $0.action.map(NSStringFromSelector) == "deleteItem" }
    assert(trashButtons.count == 1)
    assert(!trashButtons[0].isHidden)
    assert(trashButtons[0].toolTip != nil)
    assert(item(rootView,"deleteItem").target != nil)
    root.dueDateComponents = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute], from: Date())
    let dueGoal = TodoItem(reminder:root)
    let dueHierarchy = TaskHierarchy(nodes:[dueGoal.treeNode])
    assert(dueHierarchy.dailyTodayIDs().contains(dueGoal.id))
    assert(dueHierarchy.goalIDs(includeCompleted:false).contains(dueGoal.id))
    let dailyGoalRow = TodoRowView(item:dueGoal,hierarchy:dueHierarchy,availableTasks:[dueGoal],lists:[])
    dailyGoalRow.frame = NSRect(x:0,y:0,width:360,height:85)
    dailyGoalRow.layoutSubtreeIfNeeded()
    assert(dailyGoalRow.subviews.compactMap { $0 as? NSTextField }.contains { $0.stringValue.contains("Synthetic goal") })
    assert(item(dailyGoalRow,"changeSection").title == "Move to Daily Todo")
    assert(!dueGoal.isDaily && dueGoal.reminder === root)
    root.isCompleted = true // unsaved synthetic object only
    root.completionDate = Date()
    assert(TaskHierarchy(nodes:[dueGoal.treeNode]).dailyTodayIDs().contains(dueGoal.id))
    // Completed today remains visibly checked/struck through, never reorderable.
    let doneView = TodoRowView(item:dueGoal,hierarchy:TaskHierarchy(nodes:[dueGoal.treeNode]),availableTasks:[dueGoal],lists:[])
    let doneTitle = doneView.subviews.compactMap { $0 as? NSTextField }.first { $0.stringValue.contains("Synthetic goal") }!
    assert(doneTitle.attributedStringValue.attribute(.strikethroughStyle, at:0, effectiveRange:nil) as? Int == NSUnderlineStyle.single.rawValue)
    doneView.configureDailyPriority(rank:0,count:1)
    assert(!doneView.subviews.contains { $0 is DailyDragHandle })
    // Native handle, menu, and keyboard/accessibility alternatives need no reminder writes.
    daily.isCompleted = false // synthetic only
    overdueRow.configureDailyPriority(rank:1,count:3)
    let handle = overdueRow.subviews.compactMap { $0 as? DailyDragHandle }.first!
    assert(handle.acceptsFirstResponder)
    assert(handle.accessibilityCustomActions()?.count == 2)
    assert(item(overdueRow,"movePriorityUp").isEnabled)
    assert(item(overdueRow,"movePriorityDown").isEnabled)
    var moves:[Int] = []
    overdueRow.onMovePriority = { moves.append($0) }
    _ = overdueRow.perform(NSSelectorFromString("movePriorityUp"))
    _ = overdueRow.perform(NSSelectorFromString("movePriorityDown"))
    assert(moves == [-1,1])
    assert(signedLabel.textColor == .systemRed)
    assert(overdueRow.layer?.backgroundColor != nil)
    assert(!DailyDragHandle.isDragging)
    assert(!dueGoal.isDaily && dueGoal.reminder === root)
    // Optional synthetic-only off-screen raster for visual QA (no window/mouse/system store).
    if let output = ProcessInfo.processInfo.environment["DAILY_PREVIEW_PATH"] {
        let canvas = NSView(frame:NSRect(x:0,y:0,width:420,height:330))
        canvas.wantsLayer = true
        canvas.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        let title = NSTextField(labelWithString:"Daily Todo · Today")
        title.font = .systemFont(ofSize:16,weight:.semibold)
        title.frame = NSRect(x:20,y:295,width:380,height:24); canvas.addSubview(title)
        for (i, titleText) in ["Review the project draft", "Prepare tomorrow’s notes", "Read one paper"].enumerated() {
            let sample = EKReminder(eventStore:ek); sample.title = titleText
            sample.notes = "EdgeTodo-Section: daily"
            sample.dueDateComponents = Calendar.current.dateComponents([.year,.month,.day],from: i == 0 ? yesterday : Date())
            let value = TodoItem(reminder:sample)
            let row = TodoRowView(item:value,hierarchy:TaskHierarchy(nodes:[value.treeNode]),availableTasks:[value],lists:[])
            row.configureDailyPriority(rank:i,count:3)
            row.widthAnchor.constraint(equalToConstant:396).isActive = true
            row.frame = NSRect(x:12,y:225-i*65,width:396,height:58)
            canvas.addSubview(row)
        }
        let heading = NSTextField(labelWithString:"✓ Done today · 1")
        heading.font = .systemFont(ofSize:11,weight:.medium)
        heading.frame = NSRect(x:20,y:74,width:380,height:20); canvas.addSubview(heading)
        doneView.widthAnchor.constraint(equalToConstant:396).isActive = true
        doneView.frame = NSRect(x:12,y:10,width:396,height:58); canvas.addSubview(doneView)
        canvas.layoutSubtreeIfNeeded()
        if let rep = canvas.bitmapImageRepForCachingDisplay(in:canvas.bounds) {
            canvas.cacheDisplay(in:canvas.bounds,to:rep)
            try! rep.representation(using:.png,properties:[:])!.write(to:URL(fileURLWithPath:output))
        }
    }
    print("PASS: 11 completed-row and reorder accessibility checks")
    print("PASS: 6 isolated due-today goal row/identity checks")
    print("PASS: 22 isolated AppKit menu/layout checks; no real reminders or visible UI")
 }
}
