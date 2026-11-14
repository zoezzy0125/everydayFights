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
    let all = [r,c,l], tree = TaskHierarchy(nodes: all.map(\.treeNode))
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
    // Off-screen layout validation only: no window shown, screenshots or mouse input.
    leafView.frame = NSRect(x:0,y:0,width:360,height:85)
    leafView.layoutSubtreeIfNeeded()
    assert(leafView.subviews.contains { ($0 as? NSTextField)?.stringValue == "↳ Synthetic goal › Synthetic paper" })
    assert(leafView.subviews.allSatisfy { $0.frame.origin.x.isFinite && $0.frame.origin.y.isFinite })
    print("PASS: 12 isolated AppKit menu/layout checks; no real reminders or visible UI")
 }
}
