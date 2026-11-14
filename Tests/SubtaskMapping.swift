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
        print("PASS: 4 daily / emoji persistence parser tests")
        print("PASS: 5 subtask metadata compatibility checks; nothing saved")
    }
}
