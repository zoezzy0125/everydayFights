# everydayFights

An original, local-first macOS menu-bar to-do app. Small steps. A little stronger.

从零实现的轻量侧边待办工具。SwiftUI + AppKit，无第三方依赖。

> **v0.1 限制：本地 JSON 存储，不与 Apple 提醒事项/iCloud 同步，不发送系统通知。已完成编译和自动化模型测试，尚未进行 GUI 交互验收。**

## Features / 功能

- 点击菜单栏 `✓`，在当前屏幕右侧打开浮动面板；点击外部自动收起，不丢失草稿。
- 默认 **Daily Todo**，空列表展示鼓励语。未完成日常任务在之后的日期继续显示，**不修改原截止日期**。历史完成项不滚入今天。
- **Short-term Goal** 按截止日期升序显示倒计时：今日及逾期 🚨、明日 👿、2–7 天 🔥、8–30 天 🏃、31 天及以上 😌。自定义 emoji 优先。
- 新任务支持标题、日期、Today、可选时间、自定义 emoji、多条独立勾选的小事项。
- 点击日历按钮展开日期网格，可直接选月份、年份，再点具体日期。时间和日期本身不是系统通知。
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
- Completing a parent does not alter child completion flags, and vice versa. Completed parents are hidden unless “Show completed” is enabled.
- **Apple Reminders / iCloud / EventKit: no integration in v0.1.** No permissions requested, no imports, no reads or writes to system reminders, and no modification of another app's data. There are no claimed “system deadlines” to sync: original dates here belong to this app only.
- **Notifications: not implemented in v0.1.** Setting a time only stores/displays that time; it does not schedule an alert or alarm.
- This version has no task editing/deletion UI, recurring tasks, shared lists, history browser, search, cross-device sync, global hotkey, or edge-hover trigger. Use the menu-bar control to open the side panel.
- Failed reads preserve the existing file and disable saving for that run; save failures are surfaced in the panel. Back up the JSON before manual changes. Storage is local plaintext, not encrypted by the app; rely on your macOS account protections / FileVault as appropriate.

## Originality & privacy

All implementation and layout were written independently from the feature specification. No EdgeTodo source, assets, implementation, or repository history was consulted or copied. Icons are text emoji/system symbols rendered by macOS; there are no bundled third-party image assets. No analytics, network client, external dependencies, credentials, user data, or private task samples are included.

MIT license applies to this repository's original code. System fonts, emoji, and symbols are supplied by macOS under Apple's terms and are not redistributed here.

## Validation

`swift test` covers urgency boundaries, custom emoji, daily carry-forward without date mutation, future/goal exclusion, completion behavior, checklist independence, draft/task serialization, and daylight-saving calendar arithmetic. `scripts/build-app.sh` compiles a release executable and packages a signed local `.app`. CI repeats tests and packaging on macOS.

Automated tests are not a substitute for visual interaction testing. The first implementation was compiled and tested without opening a GUI or moving the owner's mouse. Manual acceptance checks remain: open/dismiss/reopen the panel, persist a draft across quit/relaunch, pick a month/year/date/time, and verify checklist clicks and scroll layout.
