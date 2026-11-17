import AppIntents
import WidgetKit

/// Interactive widget button: logs +250 ml straight into the shared App Group
/// without opening the app. The Flutter app picks up the new total on resume.
@available(iOS 17.0, *)
struct AddWaterIntent: AppIntent {
  static var title: LocalizedStringResource = "Log 250 ml of water"

  func perform() async throws -> some IntentResult {
    let defaults = UserDefaults(suiteName: "group.com.sunilkhatri.aerostep")
    let current = defaults?.integer(forKey: "hydration_ml") ?? 0
    defaults?.set(current + 250, forKey: "hydration_ml")
    WidgetCenter.shared.reloadTimelines(ofKind: "AeroStepBentoWidget")
    return .result()
  }
}
