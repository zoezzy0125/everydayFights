import Foundation
import Combine
import FightsCore
@MainActor final class Store: ObservableObject {
    @Published var tasks: [FightTask] = [] { didSet { save() } }
    @Published var draft = Draft() { didSet { save() } }
    @Published var error: String?
    private var canSave = false
    private let file: URL
    init() {
        file = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("everydayFights/tasks.json")
        do {
            if FileManager.default.fileExists(atPath: file.path) {
                let snapshot = try JSONDecoder().decode(Snapshot.self, from: Data(contentsOf: file))
                guard snapshot.version == 1 else { throw CocoaError(.coderReadCorrupt) }
                tasks = snapshot.tasks; draft = snapshot.draft
            }
            canSave = true
        } catch { self.error = "Could not read saved data. Your file has been preserved; changes will not be saved. \(error.localizedDescription)" }
    }
    private func save() {
        guard canSave else { return }
        do {
            try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONEncoder().encode(Snapshot(tasks: tasks, draft: draft)).write(to: file, options: .atomic)
        } catch { self.error = "Could not save: \(error.localizedDescription)" }
    }
    func add() {
        let title = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        let children = draft.checklistText.split(separator: "\n").map { String($0).trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }.map { ChecklistItem(title: $0) }
        tasks.append(FightTask(title: title, emoji: draft.emoji, kind: draft.kind, dueDate: draft.dueDate, includesTime: draft.includesTime, checklist: children))
        let kind = draft.kind
        draft = Draft(); draft.kind = kind
    }
}
