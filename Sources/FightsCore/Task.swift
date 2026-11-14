import Foundation
public enum TaskKind: String, Codable, CaseIterable { case daily, goal }
public struct ChecklistItem: Codable, Identifiable, Equatable {
    public var id = UUID()
    public var title: String
    public var isComplete = false
    public init(title: String) { self.title = title }
}
public struct FightTask: Codable, Identifiable, Equatable {
    public var id = UUID()
    public var title: String
    public var emoji: String
    public var kind: TaskKind
    public var dueDate: Date
    public var includesTime: Bool
    public var isComplete = false
    public var checklist: [ChecklistItem]
    public init(title: String, emoji: String = "", kind: TaskKind, dueDate: Date, includesTime: Bool = false, checklist: [ChecklistItem] = []) {
        self.title = title; self.emoji = emoji; self.kind = kind; self.dueDate = dueDate; self.includesTime = includesTime; self.checklist = checklist
    }
    public func daysRemaining(on now: Date = Date(), calendar: Calendar = .current) -> Int {
        calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: dueDate)).day ?? 0
    }
    public func badge(on now: Date = Date(), calendar: Calendar = .current) -> String {
        if !emoji.isEmpty { return emoji }
        switch daysRemaining(on: now, calendar: calendar) {
        case ...0: return "🚨"
        case 1: return "👿"
        case 2...7: return "🔥"
        case 8...30: return "🏃"
        default: return "😌"
        }
    }
    public func appearsInDaily(on day: Date, calendar: Calendar = .current) -> Bool {
        guard kind == .daily else { return false }
        let due = calendar.startOfDay(for: dueDate), shown = calendar.startOfDay(for: day)
        return due == shown || (!isComplete && due < shown)
    }
    public func countdown(on now: Date = Date()) -> String {
        let days = daysRemaining(on: now)
        if days < 0 { return "Overdue by \(-days)d" }
        if days == 0 { return "Today" }
        if days == 1 { return "Tomorrow" }
        return "\(days)d left"
    }
}
public struct Draft: Codable, Equatable {
    public var title = ""
    public var emoji = ""
    public var kind = TaskKind.daily
    public var dueDate = Date()
    public var includesTime = false
    public var checklistText = ""
    public init() {}
}
public struct Snapshot: Codable {
    public var version = 1
    public var tasks: [FightTask]
    public var draft: Draft
    public init(tasks: [FightTask] = [], draft: Draft = Draft()) { self.tasks = tasks; self.draft = draft }
}
