import SwiftUI
import FightsCore
struct ContentView: View {
    @ObservedObject var store: Store
    @State private var tab = TaskKind.daily
    @State private var composing = false
    @State private var showCompleted = false
    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("everydayFights").font(.title2.bold())
                        Text("Small steps. A little stronger.").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Menu { Button("Quit everydayFights") { NSApplication.shared.terminate(nil) } } label: { Image(systemName: "ellipsis.circle") }.menuStyle(.borderlessButton).fixedSize()
                }
                Picker("Tasks", selection: $tab) { Text("Daily Todo").tag(TaskKind.daily); Text("Short-term Goal").tag(TaskKind.goal) }.pickerStyle(.segmented)
                if let error = store.error { Text(error).font(.caption).foregroundStyle(.red).textSelection(.enabled) }
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        let visible = store.tasks.filter { task in
                            (tab == .daily ? task.appearsInDaily(on: context.date) : task.kind == .goal) && (showCompleted || !task.isComplete)
                        }.sorted { $0.dueDate < $1.dueDate }
                        if visible.isEmpty {
                            VStack(spacing: 12) {
                                Text("🌱").font(.system(size: 42))
                                Text(tab == .daily ? "A fresh day, one small win." : "Give your next goal a date.").font(.headline)
                                Text("You don't have to do everything. Just begin.").font(.caption).foregroundStyle(.secondary)
                            }.frame(maxWidth: .infinity).padding(.vertical, 35)
                        }
                        ForEach(visible) { task in
                            if let index = store.tasks.firstIndex(where: { $0.id == task.id }) {
                                TaskRow(task: $store.tasks[index], now: context.date)
                            }
                        }
                    }
                }
                Toggle("Show completed", isOn: $showCompleted).font(.caption)
                if composing {
                    ScrollView { Composer(draft: $store.draft) { store.add(); composing = false } }.frame(maxHeight: 440)
                    Button("Keep draft & collapse") { composing = false }.font(.caption)
                } else {
                    Button {
                        if store.draft.title.isEmpty && store.draft.checklistText.isEmpty { store.draft.kind = tab }
                        composing = true
                    } label: { Label(store.draft.title.isEmpty ? "New task" : "Continue draft", systemImage: "plus").frame(maxWidth: .infinity) }.buttonStyle(.borderedProminent)
                }
                Text("Local only · no Reminders access or notifications").font(.system(size: 10)).foregroundStyle(.secondary)
            }.padding(20).frame(width: 380, height: 680).background(.background)
        }
    }
}
struct TaskRow: View {
    @Binding var task: FightTask
    let now: Date
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Toggle(isOn: $task.isComplete) { Text(task.title).strikethrough(task.isComplete).font(.headline) }.toggleStyle(.checkbox)
                Spacer(minLength: 4)
                Text(task.kind == .goal ? task.badge(on: now) : (task.emoji.isEmpty ? "🌱" : task.emoji))
            }
            HStack {
                Text(task.kind == .goal ? task.countdown(on: now) : (task.daysRemaining(on: now) < 0 ? "Carried forward" : "Today"))
                Spacer()
                Text(task.dueDate, format: task.includesTime ? .dateTime.month().day().hour().minute() : .dateTime.month().day())
            }.font(.caption).foregroundStyle(.secondary)
            ForEach($task.checklist) { $item in
                Toggle(isOn: $item.isComplete) { Text(item.title).strikethrough(item.isComplete) }.toggleStyle(.checkbox).font(.subheadline).padding(.leading, 16)
            }
        }.padding(12).background(Color.accentColor.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
    }
}
struct Composer: View {
    @Binding var draft: Draft
    var onAdd: () -> Void
    @State private var calendarExpanded = false
    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            TextField("What is your next small win?", text: $draft.title)
            HStack {
                TextField("Emoji", text: $draft.emoji).frame(width: 65)
                Picker("List", selection: $draft.kind) { Text("Daily").tag(TaskKind.daily); Text("Goal").tag(TaskKind.goal) }.labelsHidden()
            }
            HStack {
                Button { calendarExpanded.toggle() } label: { Label(draft.dueDate.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar") }
                Button("Today") { draft.dueDate = Date() }
            }
            if calendarExpanded { CalendarPicker(date: $draft.dueDate) }
            Toggle("Include time", isOn: $draft.includesTime)
            if draft.includesTime { DatePicker("Time", selection: $draft.dueDate, displayedComponents: .hourAndMinute) }
            Text("Checklist · one item per line").font(.caption).foregroundStyle(.secondary)
            TextEditor(text: $draft.checklistText).frame(height: 50).overlay(RoundedRectangle(cornerRadius: 4).stroke(.quaternary))
            Button("Add task", action: onAdd).disabled(draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty).buttonStyle(.borderedProminent)
        }.textFieldStyle(.roundedBorder).padding(12).background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 12))
    }
}
