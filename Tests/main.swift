import Foundation
var cal = Calendar(identifier: .gregorian)
cal.timeZone = TimeZone(identifier: "America/New_York")!
func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 12) -> Date { cal.date(from: DateComponents(year:y, month:m, day:d, hour:h))! }
let now = date(2026, 11, 14)
assert(DayCountdown.text(due: date(2026,11,17), now:now, calendar:cal, english:false) == "剩余 3 天")
assert(DayCountdown.text(due: date(2026,11,14,18), now:now, calendar:cal, english:false) == "今天到期")
assert(DayCountdown.text(due: date(2026,11,14,9), now:now, calendar:cal, english:false) == "今天已逾期")
assert(DayCountdown.text(due: date(2026,11,12), now:now, calendar:cal, english:false) == "逾期 2 天")
assert(DayCountdown.text(due: nil, now:now, calendar:cal, english:false) == "未设日期")
assert(DayCountdown.text(due: date(2026,3,9), now:date(2026,3,7), calendar:cal, english:true) == "2d left")
assert(DayCountdown.text(due: date(2026,11,2), now:date(2026,10,31), calendar:cal, english:true) == "2d left")
assert(DayCountdown.text(due: date(2027,1,1), now:date(2026,12,31), calendar:cal, english:true) == "1d left")
print("PASS: 8 countdown cases including both DST transitions and year boundary")
let ucal = Calendar(identifier: .gregorian)
let unow = ucal.date(from: DateComponents(year: 2026, month: 11, day: 14, hour: 12))!
for (days, expected) in [(-1, "🚨"), (1, "👿"), (2, "🔥"), (7, "🔥"), (8, "🏃"), (30, "🏃"), (31, "😌")] {
    let date = ucal.date(byAdding: .day, value: days, to: unow)!
    assert(DayCountdown.urgency(due: date, now: unow, calendar: ucal) == expected)
}
assert(DayCountdown.urgency(due: nil) == "📝")
print("PASS: 8 urgency boundary cases")

let beforeMidnight = ucal.date(from: DateComponents(year: 2026, month: 11, day: 14, hour: 23, minute: 59))!
let afterMidnight = ucal.date(byAdding: .minute, value: 2, to: beforeMidnight)!
assert(DayCountdown.isToday(beforeMidnight, now: beforeMidnight, calendar: ucal))
assert(!DayCountdown.isToday(beforeMidnight, now: afterMidnight, calendar: ucal))
assert(DayCountdown.isToday(afterMidnight, now: afterMidnight, calendar: ucal))
print("PASS: 3 Daily Todo midnight boundaries")

assert(DayCountdown.inDailyToday(day: beforeMidnight, completed: false, now: afterMidnight, calendar: ucal))
assert(!DayCountdown.inDailyToday(day: beforeMidnight, completed: true, now: afterMidnight, calendar: ucal))
let later = ucal.date(byAdding: .day, value: 5, to: afterMidnight)!
assert(DayCountdown.inDailyToday(day: beforeMidnight, completed: false, now: later, calendar: ucal))
assert(!DayCountdown.inDailyToday(day: beforeMidnight, completed: true, now: later, calendar: ucal))
assert(!DayCountdown.inDailyToday(day: later, completed: false, now: afterMidnight, calendar: ucal))
assert(DayCountdown.inDailyToday(day: afterMidnight, completed: true, now: afterMidnight, calendar: ucal))
let originalDate = beforeMidnight
for _ in 0..<100 { assert(DayCountdown.inDailyToday(day: originalDate, completed: false, now: later, calendar: ucal)) }
assert(originalDate == beforeMidnight)
print("PASS: 7 virtual rollover checks (midnight, missed days, completion, future, idempotence)")
