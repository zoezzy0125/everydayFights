import Foundation

enum TaskHistoryText {
    static func render(_ nodes: [TaskHierarchy.Node], english: Bool, calendar: Calendar = .current) -> String {
        if nodes.isEmpty { return english ? "No linked Daily tasks yet." : "还没有关联的 Daily 任务。" }
        let date = DateFormatter(); date.calendar = calendar; date.timeZone = calendar.timeZone
        date.dateFormat = "yyyy-MM-dd"
        let instant = DateFormatter(); instant.calendar = calendar; instant.timeZone = calendar.timeZone
        instant.dateFormat = "yyyy-MM-dd HH:mm z"
        var group: String?, lines: [String] = []
        for n in nodes {
            let key = n.taskDate.map(date.string) ?? (english ? "Date unknown" : "日期未知")
            if key != group { lines.append("\n" + key); group = key }
            lines.append((n.completed ? "✅ " : "○ ") + n.title)
            let origin = n.due != nil ? (english ? "Task date" : "原任务日期") : (english ? "Created (no due date)" : "创建日期（未设截止日期）")
            lines.append("  " + origin + ": " + key)
            if n.completed {
                lines.append("  " + (english ? "Completed: " : "已完成：") + (n.completedAt.map(instant.string) ?? (english ? "time not recorded" : "未记录完成时间")))
            } else { lines.append(english ? "  Pending" : "  未完成") }
        }
        return lines.joined(separator: "\n")
    }
}
