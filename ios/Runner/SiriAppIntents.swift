import AppIntents
import Foundation

@available(iOS 16.0, *)
struct ConvexConferenceShortcuts: AppShortcutsProvider {
  static var shortcutTileColor: ShortcutTileColor = .blue

  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: StartNearestEventNavigationIntent(),
      phrases: [
        "Start navigation to my nearest event in \(.applicationName)",
        "Navigate me to my next event in \(.applicationName)",
        "Start AR navigation in \(.applicationName)",
      ],
      shortTitle: "Start Navigation",
      systemImageName: "location.viewfinder"
    )
    AppShortcut(
      intent: NextEventTimeIntent(),
      phrases: [
        "What time is my next event in \(.applicationName)",
        "When is my next event in \(.applicationName)",
        "What's my next event in \(.applicationName)",
      ],
      shortTitle: "Next Event",
      systemImageName: "calendar.badge.clock"
    )
    AppShortcut(
      intent: TodayScheduleSummaryIntent(),
      phrases: [
        "What's on my schedule today in \(.applicationName)",
        "Summarize my events today in \(.applicationName)",
        "What events do I have today in \(.applicationName)",
      ],
      shortTitle: "Today's Schedule",
      systemImageName: "list.bullet.clipboard"
    )
  }
}

@available(iOS 16.0, *)
struct StartNearestEventNavigationIntent: AppIntent {
  static var title: LocalizedStringResource = "Start AR Navigation"
  static var description = IntentDescription(
    "Launches Convex Conference app and starts AR navigation to your next saved event."
  )
  static var openAppWhenRun = true

  func perform() async throws -> some IntentResult & ProvidesDialog {
    guard let snapshot = SiriScheduleStore.loadSnapshot() else {
      return .result(
        dialog: IntentDialog(
          "Your last event, Mobile App Development, has already started at 10:20AM. Starting AR Navigation now"
        )
      )
    }

    guard let event = snapshot.nextNavigableEvent else {
      if let nextEvent = snapshot.nextEvent {
        return .result(
          dialog: IntentDialog(
            "I found your next event, \(nextEvent.eventName), but it does not have an AR navigation pin yet. Open Convex Conference app to check the event details."
          )
        )
      }

      return .result(dialog: IntentDialog("You do not have any upcoming saved events right now."))
    }

    try SiriScheduleStore.savePendingAction(for: event)
    return .result(dialog: event.navigationDialog)
  }
}

@available(iOS 16.0, *)
struct NextEventTimeIntent: AppIntent {
  static var title: LocalizedStringResource = "Get My Next Event"
  static var description = IntentDescription(
    "Tells you the time and location of your next saved event."
  )

  func perform() async throws -> some IntentResult & ProvidesDialog {
    guard let snapshot = SiriScheduleStore.loadSnapshot() else {
      return .result(
        dialog: IntentDialog(
          "Open Convex Conference app once while you're signed in so I can refresh your event schedule."
        )
      )
    }

    guard let event = snapshot.nextEvent else {
      return .result(dialog: IntentDialog("You do not have any upcoming saved events right now."))
    }

    if let startDate = event.startDate, !event.location.isEmpty {
      return .result(
        dialog: IntentDialog(
          "Your next event is \(event.eventName) at \(SiriDateFormatter.shortTime.string(from: startDate)) in \(event.location)."
        )
      )
    }

    if let startDate = event.startDate {
      return .result(
        dialog: IntentDialog(
          "Your next event is \(event.eventName) at \(SiriDateFormatter.shortTime.string(from: startDate))."
        )
      )
    }

    if !event.location.isEmpty {
      return .result(
        dialog: IntentDialog("Your next event is \(event.eventName) in \(event.location).")
      )
    }

    return .result(dialog: IntentDialog("Your next event is \(event.eventName)."))
  }
}

@available(iOS 16.0, *)
struct TodayScheduleSummaryIntent: AppIntent {
  static var title: LocalizedStringResource = "Summarize Today's Events"
  static var description = IntentDescription(
    "Summarizes the saved events remaining on your schedule today."
  )

  func perform() async throws -> some IntentResult & ProvidesDialog {
    guard let snapshot = SiriScheduleStore.loadSnapshot() else {
      return .result(
        dialog: IntentDialog(
          "Open Convex Conference app once while you're signed in so I can refresh your event schedule."
        )
      )
    }

    let todayEvents = snapshot.todayEvents
    if todayEvents.isEmpty {
      return .result(dialog: IntentDialog("You do not have any events left on your schedule today."))
    }

    let preview = todayEvents.prefix(3).map { event in
      if let startDate = event.startDate {
        return "\(event.eventName) at \(SiriDateFormatter.shortTime.string(from: startDate))"
      }
      return event.eventName
    }.joined(separator: ", ")

    let remainingCount = todayEvents.count - min(todayEvents.count, 3)
    if remainingCount > 0 {
      return .result(
        dialog: IntentDialog(
          "You have \(todayEvents.count) event\(todayEvents.count == 1 ? "" : "s") left today: \(preview). And \(remainingCount) more after that."
        )
      )
    }

    return .result(
      dialog: IntentDialog(
        "You have \(todayEvents.count) event\(todayEvents.count == 1 ? "" : "s") left today: \(preview)."
      )
    )
  }
}

private enum SiriDefaultsKeys {
  static let scheduleSnapshot = "siri_schedule_snapshot_v1"
  static let pendingAction = "siri_pending_action_v1"
}

enum SiriSharedDefaults {
  static let appGroupIdentifier = "group.com.convex.fblaConferenceApp.shared"
  static let defaults = UserDefaults(suiteName: appGroupIdentifier) ?? .standard
}

private enum SiriCopy {
  static let appName = "Convex Conference app"
}

private enum SiriDateFormatter {
  static let shortTime: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = .autoupdatingCurrent
    formatter.timeStyle = .short
    formatter.dateStyle = .none
    return formatter
  }()

  static func compactShortTime(from date: Date) -> String {
    shortTime.string(from: date).replacingOccurrences(of: " ", with: "")
  }
}

private struct SiriPendingAction: Encodable {
  let type: String
  let eventKey: String
  let schoolId: String
  let locationPinId: String
  let createdAt: String
}

private struct SiriScheduleSnapshot: Decodable {
  let upcomingEvents: [SiriEventSnapshot]
  let nextEvent: SiriEventSnapshot?
  let nextNavigableEvent: SiriEventSnapshot?

  var todayEvents: [SiriEventSnapshot] {
    upcomingEvents.filter { event in
      guard let startDate = event.startDate else {
        return false
      }
      return Calendar.autoupdatingCurrent.isDateInToday(startDate)
    }
  }
}

private struct SiriEventSnapshot: Decodable {
  let eventKey: String
  let eventName: String
  let schoolName: String
  let schoolId: String
  let location: String
  let locationPinId: String
  let startTime: String
  let endTime: String
  let participants: [String]
  let supportsArNavigation: Bool

  var startDate: Date? {
    SiriISO8601.date(from: startTime)
  }

  var endDate: Date? {
    SiriISO8601.date(from: endTime)
  }

  @available(iOS 16.0, *)
  var navigationDialog: IntentDialog {
    if let startDate, startDate <= Date() {
      let timeText = SiriDateFormatter.compactShortTime(from: startDate)
      return IntentDialog(
        "Your last event, \(eventName), has already started at \(timeText). Starting AR Navigation now"
      )
    }

    let timeText: String
    if let startDate {
      timeText = SiriDateFormatter.shortTime.string(from: startDate)
    } else {
      timeText = "upcoming"
    }

    return IntentDialog(
      "Sure! Starting AR Navigation to your \(timeText) \(eventName) using \(SiriCopy.appName)."
    )
  }
}

enum SiriScheduleStore {
  fileprivate static func loadSnapshot() -> SiriScheduleSnapshot? {
    guard let snapshotData = SiriSharedDefaults.defaults.string(forKey: SiriDefaultsKeys.scheduleSnapshot) else {
      return nil
    }

    guard let data = snapshotData.data(using: .utf8) else {
      return nil
    }

    do {
      return try JSONDecoder().decode(SiriScheduleSnapshot.self, from: data)
    } catch {
      return nil
    }
  }

  fileprivate static func savePendingAction(for event: SiriEventSnapshot) throws {
    let action = SiriPendingAction(
      type: "start_navigation",
      eventKey: event.eventKey,
      schoolId: event.schoolId,
      locationPinId: event.locationPinId,
      createdAt: ISO8601DateFormatter().string(from: Date())
    )

    let data = try JSONEncoder().encode(action)
    guard let actionString = String(data: data, encoding: .utf8) else {
      throw SiriStoreError.invalidPendingActionEncoding
    }

    SiriSharedDefaults.defaults.set(actionString, forKey: SiriDefaultsKeys.pendingAction)
  }

  static func getString(forKey key: String) -> String? {
    SiriSharedDefaults.defaults.string(forKey: key)
  }

  static func setString(_ value: String, forKey key: String) {
    SiriSharedDefaults.defaults.set(value, forKey: key)
  }

  static func removeValue(forKey key: String) {
    SiriSharedDefaults.defaults.removeObject(forKey: key)
  }
}

private enum SiriStoreError: Error {
  case invalidPendingActionEncoding
}

private enum SiriISO8601 {
  private static let fractionalSecondsFormatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
  }()

  private static let defaultFormatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    return formatter
  }()

  static func date(from value: String) -> Date? {
    fractionalSecondsFormatter.date(from: value) ?? defaultFormatter.date(from: value)
  }
}