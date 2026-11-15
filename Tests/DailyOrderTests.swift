import Foundation
@main struct DailyOrderTests {
 static func main() {
    let suite = "everydayFights.synthetic.order." + UUID().uuidString
    let defaults = UserDefaults(suiteName: suite)!
    defer { defaults.removePersistentDomain(forName: suite) }
    let order = DailyOrder(defaults: defaults)
    let day = Date(timeIntervalSince1970: 1700000000)
    func n(_ id: String, _ offset: Double? = nil, done: Bool = false, completion: Double? = nil) -> TaskHierarchy.Node {
        .init(id: id, parentID: id == "c" ? "a" : nil, title: id, daily: true, completed: done,
              due: day, created: offset.map { day.addingTimeInterval($0) },
              completedAt: completion.map { day.addingTimeInterval($0) })
    }
    let nodes = [n("c",3),n("a",1),n("b",2)]
    assert(order.orderedIDs(nodes:nodes) == ["a","b","c"])
    assert(order.orderedIDs(nodes:nodes + [nodes[0]]) == ["a","b","c"])
    assert(order.orderedIDs(nodes:[n("z"),n("x"),n("a",1)]) == ["a","x","z"])
    assert(order.move(id:"c",relativeTo:"a",after:false,activeIDs:["a","b","c"]))
    assert(order.orderedIDs(nodes:nodes) == ["c","a","b"])
    assert(DailyOrder(defaults:UserDefaults(suiteName:suite)!).orderedIDs(nodes:nodes) == ["c","a","b"])
    assert(order.orderedIDs(nodes:nodes + [n("d",4)]) == ["c","a","b","d"])
    assert(order.orderedIDs(nodes:[n("a",1),n("b",2),n("c",3,done:true,completion:8)]) == ["a","b","c"])
    assert(order.orderedIDs(nodes:nodes) == ["c","a","b"])
    // Hidden/completed c retains its slot when other active rows are moved.
    assert(order.move(id:"b",relativeTo:"a",after:false,activeIDs:["a","b"]))
    assert(order.orderedIDs(nodes:nodes) == ["c","b","a"])
    assert(order.orderedIDs(nodes:[n("a",1,done:true,completion:9),n("b",2,done:true,completion:8),n("c",3)]) == ["c","b","a"])
    assert(!order.move(id:"c",relativeTo:"a",after:false,activeIDs:["a","b"]))
    assert(!order.move(id:"a",relativeTo:"a",after:true,activeIDs:["a","b"]))
    assert(!order.move(id:"missing",relativeTo:"a",after:true,activeIDs:["a","b"]))
    let other = DailyOrder(defaults: defaults)
    assert(other.move(id:"a",relativeTo:"c",after:false,activeIDs:["c","b","a"]))
    // An old UI order cannot clobber the newer persisted arrangement.
    assert(order.move(id:"c",relativeTo:"b",after:true,activeIDs:["c","b","a"]))
    assert(order.orderedIDs(nodes:nodes) == ["a","b","c"])
    assert(nodes.first!.parentID == "a" && nodes.first!.due == day)
    assert(order.orderedIDs(nodes:[]).isEmpty)
    defaults.set(["a","a","c","b"],forKey:DailyOrder.storageKey)
    assert(order.orderedIDs(nodes:nodes) == ["a","c","b"])
    print("PASS: 20 local ordering checks (creation, dedup, restart, append, completion restore, hidden ranks, stale/drop validation, hierarchy unchanged)")
 }
}
