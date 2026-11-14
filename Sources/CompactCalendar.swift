import AppKit

/// Compact date grid with direct month and editable year selection.
final class CompactCalendar: NSControl, NSComboBoxDelegate {
    private let year = NSComboBox()
    private let month = NSPopUpButton()
    private let grid = NSStackView()
    private var updating = false
    var dateValue = Date() { didSet { render() } }
    override var intrinsicContentSize: NSSize { NSSize(width: 300, height: 224) }

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer?.cornerRadius = 10
        layer?.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.8).cgColor
        year.addItems(withObjectValues: (1900...2100).map(String.init))
        year.isEditable = true
        year.completes = true
        year.delegate = self
        year.target = self
        year.action = #selector(headerChanged)
        year.setAccessibilityLabel(L10n.t("年份，可直接输入", "Year, type or select"))
        let symbols = DateFormatter().monthSymbols ?? []
        month.addItems(withTitles: symbols)
        month.target = self
        month.action = #selector(headerChanged)
        month.setAccessibilityLabel(L10n.t("月份", "Month"))
        let today = NSButton(title: L10n.t("今天", "Today"), target: self, action: #selector(goToday))
        today.bezelStyle = .rounded
        today.setAccessibilityLabel(L10n.t("回到今天", "Back to today"))
        let header = NSStackView(views: [year, month, today])
        header.spacing = 8
        header.distribution = .fill
        year.widthAnchor.constraint(equalToConstant: 76).isActive = true
        today.widthAnchor.constraint(equalToConstant: 58).isActive = true
        header.translatesAutoresizingMaskIntoConstraints = false
        addSubview(header)
        grid.orientation = .vertical
        grid.spacing = 2
        grid.distribution = .fillEqually
        grid.translatesAutoresizingMaskIntoConstraints = false
        addSubview(grid)
        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            header.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            header.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            header.heightAnchor.constraint(equalToConstant: 26),
            grid.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 5),
            grid.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            grid.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            grid.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
        render()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    func comboBoxSelectionDidChange(_ notification: Notification) {
        // Selection's text is committed on the next run-loop iteration.
        DispatchQueue.main.async { [weak self] in self?.headerChanged() }
    }
    func controlTextDidEndEditing(_ obj: Notification) { headerChanged() }
    @objc private func goToday() { dateValue = Date(); sendAction(action, to: target) }
    @objc private func headerChanged() {
        guard !updating, let y = Int(year.stringValue), (1...9999).contains(y), month.indexOfSelectedItem >= 0 else { return }
        let cal = Calendar.current
        let old = cal.component(.day, from: dateValue)
        guard let first = cal.date(from: DateComponents(year: y, month: month.indexOfSelectedItem + 1, day: 1)), let range = cal.range(of: .day, in: .month, for: first), let date = cal.date(byAdding: .day, value: min(old, range.count) - 1, to: first) else { return }
        dateValue = date
        sendAction(action, to: target)
    }
    @objc private func pickDay(_ sender: NSButton) {
        let cal = Calendar.current
        var parts = cal.dateComponents([.year, .month], from: dateValue)
        parts.day = sender.tag
        if let date = cal.date(from: parts) { dateValue = date; sendAction(action, to: target) }
    }
    private func render() {
        updating = true
        defer { updating = false }
        let cal = Calendar.current
        year.stringValue = String(cal.component(.year, from: dateValue))
        month.selectItem(at: cal.component(.month, from: dateValue) - 1)
        grid.arrangedSubviews.forEach { grid.removeArrangedSubview($0); $0.removeFromSuperview() }
        let symbols = cal.veryShortWeekdaySymbols
        let weekdays = (0..<7).map { i -> NSView in
            let label = NSTextField(labelWithString: symbols[(cal.firstWeekday - 1 + i) % 7])
            label.alignment = .center
            label.font = .systemFont(ofSize: 10, weight: .medium)
            label.textColor = .secondaryLabelColor
            return label
        }
        addRow(weekdays)
        guard let first = cal.date(from: cal.dateComponents([.year, .month], from: dateValue)), let range = cal.range(of: .day, in: .month, for: first) else { return }
        let offset = (cal.component(.weekday, from: first) - cal.firstWeekday + 7) % 7
        for week in 0..<6 {
            addRow((0..<7).map { column -> NSView in
                let d = week * 7 + column - offset + 1
                guard range.contains(d) else { return NSView() }
                let b = NSButton(title: String(d), target: self, action: #selector(pickDay(_:)))
                b.tag = d
                b.isBordered = false
                b.font = .systemFont(ofSize: 12, weight: d == cal.component(.day, from: dateValue) ? .semibold : .regular)
                b.wantsLayer = true
                b.layer?.cornerRadius = 6
                if d == cal.component(.day, from: dateValue) {
                    b.layer?.backgroundColor = NSColor.controlAccentColor.cgColor
                    b.contentTintColor = .white
                }
                b.setAccessibilityLabel("\(year.stringValue)-\(month.indexOfSelectedItem + 1)-\(d)")
                return b
            })
        }
    }
    private func addRow(_ views: [NSView]) {
        let row = NSStackView(views: views)
        row.distribution = .fillEqually
        row.spacing = 3
        grid.addArrangedSubview(row)
        row.widthAnchor.constraint(equalTo: grid.widthAnchor).isActive = true
    }
}
