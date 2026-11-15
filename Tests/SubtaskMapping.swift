import Foundation
import EventKit
@main struct SubtaskMappingTest {
    static func main() {
        // Unsaved objects only: no access request, fetch, save, or delete.
        let store = EKEventStore()
        let reminder = EKReminder(eventStore: store)
        reminder.title = "Synthetic parser test"
        assert(TodoItem(reminder: reminder).parentID == nil)
        reminder.notes = "Regular user note"
        assert(TodoItem(reminder: reminder).parentID == nil)
        reminder.notes = "EdgeTodo-Parent: parent-example\nParent task: Conference"
        assert(TodoItem(reminder: reminder).parentID == "parent-example")
        reminder.notes = "Some note\nEdgeTodo-Parent: parent-example\nOther note"
        assert(TodoItem(reminder: reminder).parentID == "parent-example")
        assert(TodoItem(reminder: reminder).title == "Synthetic parser test")
        reminder.notes = "Personal note\nEdgeTodo-Section: daily\nEdgeTodo-Emoji: 🎓"
        assert(TodoItem(reminder: reminder).isDaily)
        assert(TodoItem(reminder: reminder).customEmoji == "🎓")
        reminder.notes = "Untouched old task"
        assert(!TodoItem(reminder: reminder).isDaily)
        assert(TodoItem(reminder: reminder).customEmoji == nil)
        let original = "Keep this note\nEdgeTodo-Section: daily\nEdgeTodo-Parent: parent-example"
        reminder.notes = TodoStore.deletedNotes(original, deleted: true)
        let deleted = TodoItem(reminder: reminder)
        assert(deleted.isDeleted)
        assert(!deleted.isCompleted)
        assert(deleted.parentID == "parent-example")
        assert(deleted.isDaily)
        assert(TodoStore.deletedNotes(reminder.notes, deleted: true) == reminder.notes)
        assert(TodoStore.deletedNotes(reminder.notes, deleted: false) == original)
        assert(TodoStore.deletedNotes(nil, deleted: false) == nil)
        let unlinked = TaskHierarchy.replacingParent(in: original, with: nil)
        assert(unlinked?.contains("Keep this note") == true)
        assert(unlinked?.contains("EdgeTodo-Section: daily") == true)
        assert(unlinked?.contains("EdgeTodo-Parent:") == false)
        let activeItems = [deleted].filter { !$0.isDeleted }
        assert(activeItems.isEmpty)
        assert(TaskHierarchy(nodes: activeItems.map(\.treeNode)).dailyHistory(of: "parent-example").isEmpty)
        print("PASS: 12 recoverable trash metadata/filter checks; no system writes")
        print("PASS: 4 daily / emoji persistence parser tests")
        print("PASS: 5 subtask metadata compatibility checks; nothing saved")
    }
}
