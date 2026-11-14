import Foundation

/// Pure relationship model. Reading/grouping never changes dates or creates reminders.
struct TaskHierarchy {
    struct Node {
        let id: String
        let parentID: String?
        let title: String
        let daily: Bool
        let completed: Bool
        let due: Date?
        let created: Date?
        let completedAt: Date?
        var taskDate: Date? { due ?? created }
    }
    enum Violation: String { case missing, cycle, tooDeep }
    let nodes: [Node]
    var byID: [String: Node] { Dictionary(nodes.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a }) }
    func ancestors(of id: String) -> [Node]? {
        let map = byID
        guard var node = map[id] else { return nil }
        var seen: Set<String> = [id]
        var result: [Node] = []
        while let parent = node.parentID {
            guard let next = map[parent] else { return nil }
            guard seen.insert(parent).inserted else { return nil }
            result.append(next); node = next
        }
        return result
    }
    func depth(of id: String) -> Int? { ancestors(of: id).map { $0.count + 1 } }
    func descendants(of id: String) -> [Node] {
        var result: [Node] = [], seen: Set<String> = [id], queue = [id]
        while !queue.isEmpty {
            let parent = queue.removeFirst()
            for child in nodes where child.parentID == parent && seen.insert(child.id).inserted {
                result.append(child); queue.append(child.id)
            }
        }
        return result
    }
    func violation(moving id: String, to parentID: String?) -> Violation? {
        guard byID[id] != nil else { return .missing }
        // Detaching is always allowed, including repairing old malformed relationships.
        guard let parentID else { return nil }
        guard byID[parentID] != nil else { return .missing }
        guard parentID != id, !descendants(of: id).contains(where: { $0.id == parentID }) else { return .cycle }
        let changed = nodes.map { n in
            n.id == id ? Node(id: n.id, parentID: parentID, title: n.title, daily: n.daily, completed: n.completed, due: n.due, created: n.created, completedAt: n.completedAt) : n
        }
        let tree = TaskHierarchy(nodes: changed)
        for nodeID in [id] + descendants(of: id).map(\.id) {
            guard let depth = tree.depth(of: nodeID) else { return .cycle }
            if depth > 3 { return .tooDeep }
        }
        return nil
    }
    func canAddChild(to id: String) -> Bool { depth(of: id).map { $0 < 3 } ?? false }
    func dailyHistory(of id: String) -> [Node] {
        descendants(of: id).filter(\.daily).sorted {
            let a = $0.taskDate ?? .distantPast, b = $1.taskDate ?? .distantPast
            return a == b ? $0.id < $1.id : a > b
        }
    }
    /// Goal view includes daily descendants and completed ancestors needed to reach active children.
    func goalIDs(includeCompleted: Bool = false) -> Set<String> {
        var result = Set(nodes.filter { !$0.daily && (includeCompleted || !$0.completed) }.map(\.id))
        for n in nodes where includeCompleted || !n.completed {
            guard let path = ancestors(of: n.id), path.contains(where: { !$0.daily }) else { continue }
            result.insert(n.id); path.forEach { result.insert($0.id) }
        }
        return result
    }
    /// Stable, cycle-safe preorder of a filtered set; depths reflect only visible ancestors.
    func ordered(_ ids: Set<String>) -> [(String, Int)] {
        let selected = nodes.filter { ids.contains($0.id) }
        var seen = Set<String>(), result: [(String, Int)] = []
        func append(_ id: String, _ depth: Int) {
            guard seen.insert(id).inserted else { return }
            result.append((id, min(depth, 2)))
            for n in selected where n.parentID == id { append(n.id, depth + 1) }
        }
        for n in selected where n.parentID == nil || !ids.contains(n.parentID!) { append(n.id, 0) }
        for n in selected { append(n.id, 0) }
        return result
    }
    static func replacingParent(in notes: String?, with parent: String?) -> String? {
        var lines = (notes ?? "").components(separatedBy: "\n").filter { !$0.hasPrefix("EdgeTodo-Parent: ") }
        if let parent { lines.append("EdgeTodo-Parent: " + parent) }
        let value = lines.joined(separator: "\n")
        return value.isEmpty ? nil : value
    }
}
