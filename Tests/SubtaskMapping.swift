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
        reminder.notes = original
        let child = EKReminder(eventStore: store)
        child.notes = original
        var operations: [String] = []
        try! TodoStore.performDeletion(reminder, children: [child], save: { r in
            assert(r === child); operations.append("save child")
        }, remove: { r in
            assert(r === reminder); operations.append("remove parent")
        }, commit: { operations.append("commit") }, reset: { assertionFailure("unexpected reset") })
        assert(operations == ["save child", "remove parent", "commit"])
        assert(TodoItem(reminder: child).parentID == nil)
        assert(child.notes?.contains("Keep this note") == true)
        assert(TodoItem(reminder: child).isDaily)
        assert(!reminder.isCompleted && !child.isCompleted)
        assert(reminder.notes == original)
        enum Failure: Error { case simulated }
        for failingStage in ["save", "remove", "commit"] {
            child.notes = original
            var didReset = false
            do {
                try TodoStore.performDeletion(reminder, children: [child], save: { _ in
                    if failingStage == "save" { throw Failure.simulated }
                }, remove: { _ in
                    if failingStage == "remove" { throw Failure.simulated }
                }, commit: {
                    if failingStage == "commit" { throw Failure.simulated }
                }, reset: { didReset = true })
                assertionFailure("must propagate error")
            } catch {
                assert(didReset)
                assert(child.notes == original)
                assert(!reminder.isCompleted)
            }
        }
        print("PASS: deletion transaction uses mocked operations; save/remove/commit failures roll back; no system writes")
        print("PASS: 4 daily / emoji persistence parser tests")
        print("PASS: 5 subtask metadata compatibility checks; nothing saved")
    }
}
