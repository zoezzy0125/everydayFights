import XCTest
@testable import FightsCore
final class TaskTests: XCTestCase {
    var calendar: Calendar { var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(secondsFromGMT: 0)!; return c }
    var now: Date { calendar.date(from: DateComponents(year: 2026, month: 11, day: 14))! }
    func task(_ days: Int, kind: TaskKind = .goal) -> FightTask { FightTask(title: "Synthetic test", kind: kind, dueDate: calendar.date(byAdding: .day, value: days, to: now)!) }
    func testAllBadgeBoundaries() {
        for (days, badge) in [(-1,"🚨"),(0,"🚨"),(1,"👿"),(2,"🔥"),(7,"🔥"),(8,"🏃"),(30,"🏃"),(31,"😌")] { XCTAssertEqual(task(days).badge(on: now, calendar: calendar), badge) }
    }
    func testCustomEmojiOverridesBadge() { var t = task(1); t.emoji = "🎯"; XCTAssertEqual(t.badge(on: now), "🎯") }
    func testCarryForwardNeverMutatesDeadline() {
        let t = task(-3, kind: .daily), original = t.dueDate
        XCTAssertTrue(t.appearsInDaily(on: now, calendar: calendar)); XCTAssertEqual(t.dueDate, original)
        XCTAssertFalse(task(1, kind: .daily).appearsInDaily(on: now, calendar: calendar))
        XCTAssertFalse(task(0).appearsInDaily(on: now, calendar: calendar))
    }
    func testCompletedDoesNotCarryForward() { var t = task(-1, kind: .daily); t.isComplete = true; XCTAssertFalse(t.appearsInDaily(on: now, calendar: calendar)) }
    func testChecklistIndependentFromParent() {
        var t = task(0); t.checklist = [ChecklistItem(title: "A"), ChecklistItem(title: "B")]
        t.checklist[0].isComplete = true
        XCTAssertFalse(t.isComplete); XCTAssertFalse(t.checklist[1].isComplete)
        t.isComplete = true; XCTAssertFalse(t.checklist[1].isComplete)
    }
    func testDraftAndTasksRoundTrip() throws {
        var d = Draft(); d.title = "Unsaved synthetic draft"; d.checklistText = "A\nB"; d.includesTime = true
        let s = Snapshot(tasks: [task(0)], draft: d)
        let decoded = try JSONDecoder().decode(Snapshot.self, from: JSONEncoder().encode(s))
        XCTAssertEqual(decoded.tasks, s.tasks); XCTAssertEqual(decoded.draft, d)
    }
    func testCalendarDayAcrossDST() {
        var c = calendar; c.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        let start = c.date(from: DateComponents(year: 2026, month: 3, day: 8))!
        let end = c.date(byAdding: .day, value: 1, to: start)!
        let t = FightTask(title: "DST", kind: .goal, dueDate: end)
        XCTAssertEqual(t.daysRemaining(on: start, calendar: c), 1)
    }
}
