import Foundation
import EventKit
import AppKit

// MARK: - 列表项包装

struct TodoItem: Identifiable, Equatable {
    let reminder: EKReminder

    var id: String { reminder.calendarItemIdentifier }
    func metadata(_ key: String) -> String? {
        let prefix = "EdgeTodo-" + key + ": "
        return reminder.notes?.components(separatedBy: "\n").first(where: { $0.hasPrefix(prefix) }).map { String($0.dropFirst(prefix.count)) }
    }
    var isDaily: Bool { metadata("Section") == "daily" }
    var customEmoji: String? { metadata("Emoji") }
    var day: Date { due ?? reminder.creationDate ?? Date() }
    var parentID: String? {
        let prefix = "EdgeTodo-Parent: "
        return reminder.notes?.components(separatedBy: "\n").first(where: { $0.hasPrefix(prefix) }).map { String($0.dropFirst(prefix.count)) }
    }
    var treeNode: TaskHierarchy.Node {
        .init(id: id, parentID: parentID, title: title, daily: isDaily, completed: isCompleted,
              due: due, created: reminder.creationDate, completedAt: reminder.completionDate)
    }
    var title: String { reminder.title ?? L10n.t("（无标题）", "(No title)") }
    var isCompleted: Bool { reminder.isCompleted }

    var due: Date? {
        guard let c = reminder.dueDateComponents else { return nil }
        return Calendar.current.date(from: c)
    }

    static func == (lhs: TodoItem, rhs: TodoItem) -> Bool {
        lhs.id == rhs.id
            && lhs.title == rhs.title
            && lhs.due == rhs.due
            && lhs.isCompleted == rhs.isCompleted
    }
}

// MARK: - 数据层：直接读写系统「提醒事项」

final class TodoStore {
    static let shared = TodoStore()

    let ek = EKEventStore()

    private(set) var lists: [EKCalendar] = []
    private(set) var items: [TodoItem] = []
    private(set) var allItems: [TodoItem] = []
    private(set) var authGranted: Bool = false
    private(set) var authDenied: Bool = false
    private(set) var lastError: String?

    /// 任何数据变化都会回调（主线程）
    var onChange: (() -> Void)?

    var selectedListID: String? {
        get { UserDefaults.standard.string(forKey: "selectedListID") }
        set {
            UserDefaults.standard.set(newValue, forKey: "selectedListID")
            reload()
        }
    }

    private init() {
        NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged, object: ek, queue: .main
        ) { [weak self] _ in
            self?.reload()
        }
        let status = EKEventStore.authorizationStatus(for: .reminder)
        applyAuth(status)
        if status == .notDetermined {
            requestAccess()
        } else if authGranted {
            reload()
        }
    }

    // MARK: 权限

    private func applyAuth(_ status: EKAuthorizationStatus) {
        if #available(macOS 14.0, *) {
            authGranted = (status == .fullAccess)
        } else {
            authGranted = (status == .authorized)
        }
        authDenied = (status == .denied || status == .restricted)
    }

    func requestAccess() {
        let done: (Bool, Error?) -> Void = { [weak self] granted, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.applyAuth(EKEventStore.authorizationStatus(for: .reminder))
                if granted {
                    self.lastError = nil
                    self.reload()
                } else if let error = error {
                    self.lastError = error.localizedDescription
                    self.notify()
                } else {
                    self.notify()
                }
            }
        }
        if #available(macOS 14.0, *) {
            ek.requestFullAccessToReminders(completion: done)
        } else {
            ek.requestAccess(to: .reminder, completion: done)
        }
    }

    func openPrivacySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Reminders") {
            NSWorkspace.shared.open(url)
        }
    }

    func openRemindersApp() {
        let url = URL(fileURLWithPath: "/System/Applications/Reminders.app")
        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration()) { _, _ in }
    }

    // MARK: 读取

    var selectedList: EKCalendar? {
        if let id = selectedListID, let cal = ek.calendar(withIdentifier: id) {
            return cal
        }
        return ek.defaultCalendarForNewReminders() ?? lists.first
    }

    func reload() {
        applyAuth(EKEventStore.authorizationStatus(for: .reminder))
        guard authGranted else {
            lists = []
            items = []
            notify()
            return
        }
        lists = ek.calendars(for: .reminder)
            .sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }

        guard let cal = selectedList else {
            items = []
            notify()
            return
        }
        let predicate = ek.predicateForReminders(in: [cal])
        ek.fetchReminders(matching: predicate) { [weak self] found in
            DispatchQueue.main.async { self?.apply(found ?? []) }
        }
    }

    private func apply(_ raw: [EKReminder]) {
        allItems = raw.map { TodoItem(reminder: $0) }
        let active = allItems.filter { !$0.isCompleted }.map(\.reminder)
        let sorted = active.sorted { a, b in
            let da = a.dueDateComponents.flatMap { Calendar.current.date(from: $0) }
            let db = b.dueDateComponents.flatMap { Calendar.current.date(from: $0) }
            switch (da, db) {
            case let (x?, y?):
                if x != y { return x < y }
            case (_?, nil):
                return true
            case (nil, _?):
                return false
            default:
                break
            }
            let ca = a.creationDate ?? Date.distantPast
            let cb = b.creationDate ?? Date.distantPast
            return ca > cb
        }
        items = sorted.map { TodoItem(reminder: $0) }
        notify()
    }

    private func notify() {
        onChange?()
    }

    var hierarchy: TaskHierarchy { TaskHierarchy(nodes: allItems.map(\.treeNode)) }

    @discardableResult
    func link(_ item: TodoItem, to parent: TodoItem?) -> Bool {
        guard allItems.contains(where: { $0.id == item.id }),
              parent == nil || allItems.contains(where: { $0.id == parent!.id }),
              parent == nil || parent!.reminder.calendar.calendarIdentifier == item.reminder.calendar.calendarIdentifier else {
            lastError = L10n.t("只能关联当前同一提醒列表中的任务。", "Choose a task from the same Reminders list.")
            notify(); return false
        }
        if let problem = hierarchy.violation(moving: item.id, to: parent?.id) {
            lastError = problem == .tooDeep
                ? L10n.t("最多三级，移动整个子树也不能超过三级。", "Maximum three levels, including the entire moved subtree.")
                : L10n.t("不能关联自身、后代或无效任务。", "Cannot link to self, a descendant, or an invalid task.")
            notify(); return false
        }
        let oldNotes = item.reminder.notes
        item.reminder.notes = TaskHierarchy.replacingParent(in: oldNotes, with: parent?.id)
        do {
            try ek.save(item.reminder, commit: true)
            lastError = nil; reload(); return true
        } catch {
            item.reminder.notes = oldNotes
            lastError = error.localizedDescription; notify(); return false
        }
    }

    // MARK: 写入

    @discardableResult
    func add(title: String, due: Date?, parent: TodoItem? = nil, daily: Bool? = nil) -> Bool {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        guard let cal = selectedList else {
            lastError = L10n.t(
                "没有可用的列表，请先在「提醒事项」中建一个",
                "No lists available — create one in Reminders first"
            )
            notify()
            return false
        }
        if let parent, !hierarchy.canAddChild(to: parent.id) {
            lastError = L10n.t("最多三级，不能在第三级任务下继续添加。", "Maximum three levels; this task cannot have another child.")
            notify(); return false
        }
        let r = EKReminder(eventStore: ek)
        r.title = trimmed
        r.calendar = parent?.reminder.calendar ?? cal
        if let parent {
            r.notes = "EdgeTodo-Parent: \(parent.id)\n" + L10n.t("所属事项：", "Parent task: ") + parent.title
        }
        if daily ?? parent?.isDaily ?? false {
            r.notes = (r.notes.map { $0 + "\n" } ?? "") + "EdgeTodo-Section: daily"
        }
        if let due = due { Self.applyDue(r, due) }
        do {
            try ek.save(r, commit: true)
            lastError = nil
            reload()
            return true
        } catch {
            lastError = error.localizedDescription
            notify()
            return false
        }
    }

    static func applyDue(_ reminder: EKReminder, _ date: Date) {
        var comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        comps.timeZone = TimeZone.current
        reminder.dueDateComponents = comps
        reminder.alarms = [EKAlarm(absoluteDate: date)]
    }

    func setMetadata(_ item: TodoItem, key: String, value: String?) {
        let prefix = "EdgeTodo-" + key + ": "
        var lines = (item.reminder.notes ?? "").components(separatedBy: "\n").filter { !$0.hasPrefix(prefix) }
        if let value, !value.isEmpty { lines.append(prefix + value) }
        item.reminder.notes = lines.joined(separator: "\n")
        persist(item)
    }

    func complete(_ item: TodoItem) {
        item.reminder.isCompleted = true
        item.reminder.completionDate = Date()
        do {
            try ek.save(item.reminder, commit: true)
            items.removeAll { $0.id == item.id }
            notify()
            reload()
        } catch {
            lastError = error.localizedDescription
            notify()
        }
    }

    func setDue(_ item: TodoItem, _ date: Date?) {
        if let date = date {
            Self.applyDue(item.reminder, date)
        } else {
            item.reminder.alarms = []
            item.reminder.dueDateComponents = nil
        }
        persist(item)
    }

    func move(_ item: TodoItem, to calendar: EKCalendar) {
        item.reminder.calendar = calendar
        persist(item)
    }

    /// Called only after the row's explicit destructive confirmation.
    @discardableResult
    func delete(_ item: TodoItem) -> Bool {
        guard allItems.contains(where: { $0.id == item.id }) else { return false }
        let children = allItems.filter { $0.parentID == item.id }.map(\.reminder)
        do {
            try Self.performDeletion(item.reminder, children: children,
                save: { try self.ek.save($0, commit: false) },
                remove: { try self.ek.remove($0, commit: false) },
                commit: { try self.ek.commit() }, reset: { self.ek.reset() })
            lastError = nil; reload(); return true
        } catch {
            lastError = error.localizedDescription; reload(); return false
        }
    }

    // Injectable operations allow testing without touching real reminders.
    static func performDeletion(_ reminder: EKReminder, children: [EKReminder],
        save: (EKReminder) throws -> Void, remove: (EKReminder) throws -> Void,
        commit: () throws -> Void, reset: () -> Void) throws {
        let oldNotes = children.map(\.notes)
        do {
            for child in children {
                child.notes = TaskHierarchy.replacingParent(in: child.notes, with: nil)
                try save(child)
            }
            // Removing the reminder also removes its alarms; never mark it complete.
            try remove(reminder)
            try commit()
        } catch {
            reset()
            for (child, notes) in zip(children, oldNotes) { child.notes = notes }
            throw error
        }
    }

    private func persist(_ item: TodoItem) {
        do {
            try ek.save(item.reminder, commit: true)
            reload()
        } catch {
            lastError = error.localizedDescription
            notify()
        }
    }
}
