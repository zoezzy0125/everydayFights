import Foundation

/// Device-local display order only. Never changes reminders, due dates, or hierarchy.
/// Access on the main thread (the panel is the only writer).
final class DailyOrder {
    static let storageKey = "everydayFights.dailyOrder.v1"
    private let defaults: UserDefaults
    init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    private func unique(_ ids: [String]) -> [String] {
        var seen = Set<String>()
        return ids.filter { seen.insert($0).inserted }
    }
    private var saved: [String] { unique(defaults.stringArray(forKey: Self.storageKey) ?? []) }

    func orderedIDs(nodes: [TaskHierarchy.Node]) -> [String] {
        let map = Dictionary(nodes.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let baseline = map.values.sorted {
            let a = $0.created ?? .distantFuture, b = $1.created ?? .distantFuture
            return a == b ? $0.id < $1.id : a < b
        }
        let rank = unique(saved + baseline.map(\.id))
        let active = rank.filter { map[$0]?.completed == false }
        let completed = baseline.filter(\.completed).sorted {
            let a = $0.completedAt ?? .distantPast, b = $1.completedAt ?? .distantPast
            return a == b ? $0.id < $1.id : a < b
        }.map(\.id)
        return active + completed
    }

    /// Only current unfinished rows may be moved. Invalid/stale drops do nothing.
    /// Re-read persisted order to avoid replacing a newer order with a stale row snapshot.
    @discardableResult
    func move(id: String, relativeTo targetID: String, after: Bool, activeIDs: [String]) -> Bool {
        let active = unique(activeIDs), allowed = Set(active)
        guard id != targetID, allowed.contains(id), allowed.contains(targetID) else { return false }
        let all = unique(saved + active)
        var reordered = all.filter { allowed.contains($0) }
        guard let source = reordered.firstIndex(of: id) else { return false }
        reordered.remove(at: source)
        guard let destination = reordered.firstIndex(of: targetID) else { return false }
        reordered.insert(id, at: destination + (after ? 1 : 0))
        var index = 0
        let merged = all.map { current -> String in
            guard allowed.contains(current) else { return current }
            defer { index += 1 }
            return reordered[index]
        }
        guard merged != all else { return false }
        defaults.set(merged, forKey: Self.storageKey)
        return true
    }
}
