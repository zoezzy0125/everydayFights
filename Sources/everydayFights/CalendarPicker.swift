import SwiftUI
/// An inline calendar avoids a separate key window so outside-click dismissal stays predictable.
struct CalendarPicker: View {
    @Binding var date: Date
    private let calendar = Calendar.current
    private var month: Int { calendar.component(.month, from: date) }
    private var year: Int { calendar.component(.year, from: date) }
    private func select(year: Int, month: Int, day: Int) {
        var parts = calendar.dateComponents([.hour, .minute], from: date)
        parts.year = year; parts.month = month; parts.day = 1
        guard let first = calendar.date(from: parts), let range = calendar.range(of: .day, in: .month, for: first) else { return }
        parts.day = min(day, range.count)
        if let value = calendar.date(from: parts) { date = value }
    }
    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Picker("Month", selection: Binding(get: { month }, set: { select(year: year, month: $0, day: calendar.component(.day, from: date)) })) {
                    ForEach(1...12, id: \.self) { Text(calendar.monthSymbols[$0 - 1]).tag($0) }
                }.labelsHidden()
                Picker("Year", selection: Binding(get: { year }, set: { select(year: $0, month: month, day: calendar.component(.day, from: date)) })) {
                    ForEach((min(year, calendar.component(.year, from: Date())) - 10)...(max(year, calendar.component(.year, from: Date())) + 30), id: \.self) { Text(String($0)).tag($0) }
                }.labelsHidden()
            }
            let first = calendar.date(from: DateComponents(year: year, month: month, day: 1))!
            let offset = (calendar.component(.weekday, from: first) - calendar.firstWeekday + 7) % 7
            let count = calendar.range(of: .day, in: .month, for: first)!.count
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 3) {
                ForEach(0..<7, id: \.self) { index in
                    Text(calendar.veryShortWeekdaySymbols[(index + calendar.firstWeekday - 1) % 7]).font(.caption2).foregroundStyle(.secondary)
                }
                ForEach(0..<(offset + count), id: \.self) { index in
                    if index < offset { Color.clear.frame(height: 20) }
                    else {
                        let day = index - offset + 1
                        Button(String(day)) { select(year: year, month: month, day: day) }
                            .buttonStyle(.plain).frame(maxWidth: .infinity).frame(height: 20)
                            .background(calendar.component(.day, from: date) == day ? Color.accentColor.opacity(0.3) : .clear, in: RoundedRectangle(cornerRadius: 4))
                    }
                }
            }
        }
    }
}
