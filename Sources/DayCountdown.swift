import Foundation

/// Calendar-day countdown, not rounded 24-hour intervals (DST safe).
enum DayCountdown {
    /// Virtual rollover only: never changes the reminder date, alarm, or identity.
    static func inDailyToday(day: Date, completed: Bool, now: Date = Date(), calendar: Calendar = .current) -> Bool {
        if completed { return calendar.isDate(day, inSameDayAs: now) }
        return calendar.startOfDay(for: day) <= calendar.startOfDay(for: now)
    }
    /// Signed calendar-day delta from today; completed tasks never show as overdue.
    static func dailyOverdue(day: Date, completed: Bool, now: Date = Date(), calendar: Calendar = .current) -> Bool {
        !completed && calendar.startOfDay(for: day) < calendar.startOfDay(for: now)
    }
    static func dailyText(day: Date, completed: Bool, now: Date = Date(), calendar: Calendar = .current, english: Bool) -> String {
        if completed { return english ? "Done" : "已完成" }
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: day)).day ?? 0
        if days < 0 { return english ? "\(days)d overdue" : "\(days) 天 · 已延期" }
        return days == 0 ? (english ? "Today" : "今天") : (english ? "Kept" : "保留")
    }
    static func isToday(_ day: Date, now: Date = Date(), calendar: Calendar = .current) -> Bool { calendar.isDate(day, inSameDayAs: now) }
    static func urgency(due: Date?, now: Date = Date(), calendar: Calendar = .current) -> String {
        guard let due else { return "📝" }
        if due < now { return "🚨" }
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: due)).day ?? 0
        if days <= 1 { return "👿" }
        if days <= 7 { return "🔥" }
        if days <= 30 { return "🏃" }
        return "😌"
    }
    static func text(due: Date?, now: Date = Date(), calendar: Calendar = .current, english: Bool) -> String {
        guard let due else { return english ? "No date" : "未设日期" }
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: due)).day ?? 0
        if days > 0 { return english ? "\(days)d left" : "剩余 \(days) 天" }
        if days < 0 { return english ? "\(-days)d overdue" : "逾期 \(-days) 天" }
        if due < now { return english ? "Overdue today" : "今天已逾期" }
        return english ? "Today" : "今天到期" }
}
