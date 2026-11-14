# everydayFights

A lightweight macOS side-panel to-do utility, based on [tangbonze/EdgeTodo](https://github.com/tangbonze/EdgeTodo) v1.3.2.

[完整中文使用说明](README.md)

## Quick start

Apple Silicon Mac, macOS 13+, and Xcode Command Line Tools are required. No prebuilt installer for this revision is published yet.

```sh
git clone https://github.com/zoezzy0125/everydayFights.git
cd everydayFights
./scripts/test.sh
./build.sh
# Optional: ./package.sh
```

Quit any existing EdgeTodo instance and copy `dist/EdgeTodo.app` to Applications. The app retains the EdgeTodo bundle name and ID for compatibility. Do not run the original and this variant simultaneously. Builds are ad-hoc signed, not Apple-notarized. Only run software you trust; do not disable Gatekeeper. macOS may request Reminders authorization again after rebuilding.

## Using the app

- Open the panel using the edge handle or **Option–Command–T**. Click outside to dismiss it without discarding the unsaved draft.
- **Daily Todo** opens by default. Enter a title, choose the date/year/month and time, then press Add or Return. **Today** selects today without changing the time.
- Unfinished daily tasks from earlier days stay visible today until completed. This is a display-only carry-forward: original due dates and alarms are unchanged, no duplicate tasks or daily alarms are created.
- **History & plans** retains past, future and completed daily items.
- **Short-term Goal** sorts by deadline and displays a calendar-day countdown. Automatic urgency: over 30 days 😌, 8–30 days 🏃, 2–7 days 🔥, today/tomorrow 👿, already due 🚨. Today's Daily tasks use 🚨.
- Right-click a task for **Task emoji**, **Add Subtask…**, deadline editing, or moving between Daily Todo and Short-term Goal. Custom icons appear alongside urgency icons.
- Subtasks inherit the parent's deadline by default but can have their own date/time and completion state. Completing the parent does not complete its subtasks.

## Data and limitations

Data is stored directly in Apple Reminders, with sync controlled by the chosen account/list and iCloud settings. Reminders read/write access is required. Optional speech input needs separate microphone and speech-recognition access; do not assume offline recognition on every system.

Classification, icons and parent associations are metadata in reminder notes (`EdgeTodo-Section`, `EdgeTodo-Emoji`, `EdgeTodo-Parent`). Ordinary notes are retained. Subtasks are **independent system reminders**, grouped visually here, not native Reminders nesting. Parent IDs may not resolve identically on another Mac.

This source replaces the repository's earlier independent JSON app. It does not import or delete that app's JSON data. Retain any private migration/export backups outside the repository.

The local build passed 35 logic checks and compilation; several full UI flows have not completed end-to-end regression testing. No private reminders, exports, screenshots, or credentials are included.

## Attribution and permission

Thanks to **tangbonze**, author of EdgeTodo. The maintainer has confirmed obtaining the author's permission to publish this customized version. Upstream does not provide a general open-source license; this statement is not an MIT license or blanket permission for further redistribution. Contact the relevant rights holders about reuse, modification, distribution, or commercial use. The MIT notice on older, independently implemented historical commits does **not** apply to this EdgeTodo-derived revision.
