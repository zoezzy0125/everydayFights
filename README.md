# everydayFights

An original, local-first macOS menu-bar to-do app. Small steps. A little stronger.

从零实现的轻量侧边待办工具。SwiftUI + AppKit，无第三方依赖。

> **v0.1 限制：本地 JSON 存储，不与 Apple 提醒事项/iCloud 同步，不发送系统通知。已完成编译和自动化模型测试，主界面、空态、草稿输入、日历展开、侧边拉手展开/收起已做有限 GUI 检查，完整交互回归尚未完成。**

## Features / 功能

- 点击屏幕右侧边缘的小拉手（或菜单栏 `✓`），打开右侧浮动面板；点击外部自动收起，不丢失草稿。
- 默认 **Daily Todo**，空列表展示鼓励语。未完成日常任务在之后的日期继续显示，**不修改原截止日期**。历史完成项不滚入今天。
- **Short-term Goal** 按截止日期升序显示倒计时：今日及逾期 🚨、明日 👿、2–7 天 🔥、8–30 天 🏃、31 天及以上 😌。自定义 emoji 优先。
- 新任务支持标题、日期、Today、可选时间、自定义 emoji、多条独立勾选的小事项。
- 点击日历按钮展开公历日期网格，可直接选月份、年份，再点具体日期。时间和日期本身不是系统通知。
- 草稿和任务即时原子写入本地 JSON；关闭面板、退出应用、重新启动后仍保留。

## Build / 编译安装

Requires macOS 13+, Xcode 15+ or a compatible Swift 5.9+ macOS toolchain.

```sh
git clone https://github.com/zoezzy0125/everydayFights.git
cd everydayFights
swift test
./scripts/build-app.sh
```

结果为 `dist/everydayFights.app`，手动复制到 Applications，然后双击运行。应用没有 Dock 图标，通过菜单栏 `✓` 打开；面板右上角菜单可退出。构建脚本不会启动、安装应用或读取任何真实事项。

If running inside a restricted automation sandbox that prevents SwiftPM's nested sandbox, use `swift test --disable-sandbox` and `./scripts/build-app.sh --disable-sandbox`. This flag affects the build process, not system security settings.

This initial release is source-first. The local app is ad-hoc signed, **not Developer ID signed or notarized**, and not a universal binary. It targets the architecture of the build Mac. No installer, auto-updater, or login-item registration is included.

## Data model & compatibility / 数据与兼容性

- `FightTask`: UUID, title, custom emoji, daily/goal kind, original deadline, optional-time flag, completion flag, independent checklist items.
- `Draft`: persistent new-task editor fields, including one checklist item per line.
- Versioned `Snapshot` stores both in `~/Library/Application Support/everydayFights/tasks.json`.
- Daily carry-forward is a **view predicate**, not a deadline rewrite. Countdown uses local calendar days rather than 24-hour intervals. The interface refreshes every 30 seconds while visible.
- Completing a parent does not alter child completion flags, and vice versa. Completed goals can be revealed with “Show completed”. In Daily Todo, this switch only reveals completed tasks whose original deadline is today. A carried-forward task disappears after completion and cannot currently be reopened from the UI; a history browser is not implemented.
- **Apple Reminders / iCloud / EventKit: no integration in v0.1.** The app requests no Reminders permission and does not read or write system reminders. An optional one-time local snapshot importer is provided below; it is not synchronization. There are no claimed “system deadlines” to sync: dates are stored locally, including unchanged original dates when explicitly imported.
- **Notifications: not implemented in v0.1.** Setting a time only stores/displays that time; it does not schedule an alert or alarm.
- This version has no task editing/deletion UI, recurring tasks, shared lists, history browser, search, cross-device sync, global hotkey, or edge-hover trigger. Click the right-edge handle or menu-bar control to open the side panel.
- Failed reads preserve the existing file and disable saving for that run; save failures are surfaced in the panel. Back up the JSON before manual changes. Storage is local plaintext, not encrypted by the app; rely on your macOS account protections / FileVault as appropriate.

## Originality & privacy

All implementation and layout were written independently from the feature specification. No EdgeTodo source, assets, implementation, or repository history was consulted or copied. Icons are text emoji/system symbols rendered by macOS; there are no bundled third-party image assets. No analytics, network client, external dependencies, credentials, user data, or private task samples are included.

MIT license applies to this repository's original code. System fonts, emoji, and symbols are supplied by macOS under Apple's terms and are not redistributed here.

## Validation

`swift test` covers urgency boundaries, custom emoji, daily carry-forward without date mutation, future/goal exclusion, completion behavior, checklist independence, draft/task serialization, and daylight-saving calendar arithmetic. `scripts/build-app.sh` compiles a release executable and packages a signed local `.app`. CI repeats tests and packaging on macOS.

Automated tests are not a substitute for visual interaction testing. An authorized GUI pass verified the main screen, empty state, draft entry, calendar expansion, and draft collapse. The independently implemented right-edge handle was then visually verified: closing the panel leaves the handle visible, and clicking it reopens the Daily Todo panel. Manual acceptance checks remain: open/dismiss/reopen the panel, persist a draft across quit/relaunch, pick a month/year/date/time, and verify checklist clicks and scroll layout.

## One-time local migration

`scripts/import-reminders-snapshot.py` can copy an explicitly authorized, read-only Reminders JSON export into the local store while the app is stopped. It never calls Reminders, never updates/deletes source items, and skips already-imported source IDs. Keep exports and backups outside this repository.

The export schema is a list of `{id, name, reminders}` groups. Each reminder contains `id`, `name`, `body`, `completed`, `dueDate`, `alldayDueDate`, and `containerId`; dates are ISO 8601 strings or null. Parent containers must match the list ID; unsupported or unknown nested relationships abort rather than silently flattening.

The importer recognizes the data note `EdgeTodo-Section: daily`; under the explicitly confirmed migration convention, other items become goals. Original titles (including embedded emoji), completion flags, notes, IDs, and deadlines are retained. Missing deadlines stay missing and display “No deadline”, not an invented date. No independent custom-emoji metadata is inferred. The full source export should be retained to preserve fields not rendered by this app, such as alarms, priority, flags, and completion timestamps. No imported alarms are scheduled.

```sh
# Quit everydayFights first. Use an export you have permission to read.
python3 scripts/import-reminders-snapshot.py /path/to/private-export.json \
  --destination "$HOME/Library/Application Support/everydayFights/tasks.json"
```

A pre-import JSON backup is written in the destination's `migration` directory. To roll back, quit the app, preserve any newer local tasks, then restore that backup to `tasks.json`. Re-running the importer does not synchronize later source changes or overwrite existing local tasks.
