import EventKit
import Foundation

let store = EKEventStore()
let semaphore = DispatchSemaphore(value: 0)

store.requestFullAccessToEvents { granted, error in
    defer { semaphore.signal() }
    guard granted else { return }

    let now = Date()
    let tonight = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: now)!
    let predicate = store.predicateForEvents(withStart: now, end: tonight, calendars: nil)
    let events = store.events(matching: predicate).sorted { $0.startDate < $1.startDate }

    for event in events {
        let title = event.title ?? ""
        let df = DateFormatter()
        df.dateFormat = "h:mma"
        let start = df.string(from: event.startDate)
        let end = df.string(from: event.endDate)
        let location = event.location ?? ""
        let notes = event.notes ?? ""
        let status = event.status.rawValue // 0=none, 1=confirmed, 2=tentative, 3=canceled

        // Skip canceled
        if status == 3 { continue }

        // Output pipe-delimited
        print("\(title)|\(start)-\(end)|\(location)|\(notes.replacingOccurrences(of: "\n", with: "\\n"))")
    }
}

semaphore.wait()
