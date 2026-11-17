import SwiftUI
import WidgetKit

// Shared with the Flutter app via home_widget (App Group).
private let appGroup = "group.com.sunilkhatri.aerostep"

private let tangerine = Color(red: 1.0, green: 0.478, blue: 0.184) // #FF7A2F
private let tangerineLight = Color(red: 1.0, green: 0.631, blue: 0.388) // #FFA163
private let charcoal = Color(red: 0.078, green: 0.078, blue: 0.086) // #141416
private let skyCyan = Color(red: 0.275, green: 0.812, blue: 0.996) // #46CFFE
private let peachTop = Color(red: 1.0, green: 0.992, blue: 0.984) // #FFFDFB
private let peachBottom = Color(red: 0.992, green: 0.910, blue: 0.843) // #FDE8D7

struct AeroEntry: TimelineEntry {
  let date: Date
  let steps: Int
  let goal: Int
  let kcal: Int
  let cadence: Int
  let hydrationMl: Int

  var progress: Double { goal > 0 ? min(Double(steps) / Double(goal), 1) : 0 }

  static let placeholder = AeroEntry(date: Date(), steps: 8420, goal: 10000, kcal: 380, cadence: 118, hydrationMl: 1750)
}

struct AeroProvider: TimelineProvider {
  func placeholder(in context: Context) -> AeroEntry { .placeholder }

  func getSnapshot(in context: Context, completion: @escaping (AeroEntry) -> Void) {
    completion(context.isPreview ? .placeholder : read())
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<AeroEntry>) -> Void) {
    // The app pushes fresh values via HomeWidget.updateWidget; this is a fallback refresh.
    let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
    completion(Timeline(entries: [read()], policy: .after(next)))
  }

  private func read() -> AeroEntry {
    let d = UserDefaults(suiteName: appGroup)
    return AeroEntry(
      date: Date(),
      steps: d?.integer(forKey: "steps") ?? 0,
      goal: max(d?.integer(forKey: "goal") ?? 10000, 1),
      kcal: d?.integer(forKey: "kcal") ?? 0,
      cadence: d?.integer(forKey: "cadence") ?? 0,
      hydrationMl: d?.integer(forKey: "hydration_ml") ?? 0
    )
  }
}

private func formatted(_ n: Int) -> String {
  let f = NumberFormatter()
  f.numberStyle = .decimal
  return f.string(from: NSNumber(value: n)) ?? "\(n)"
}

struct StepRing: View {
  let progress: Double
  var body: some View {
    ZStack {
      Circle().stroke(Color.white.opacity(0.25), lineWidth: 7)
      Circle()
        .trim(from: 0, to: progress)
        .stroke(Color.white, style: StrokeStyle(lineWidth: 7, lineCap: .round))
        .rotationEffect(.degrees(-90))
      Text("\(Int(progress * 100))%")
        .font(.system(size: 13, weight: .bold, design: .rounded))
        .monospacedDigit()
        .foregroundColor(.white)
    }
  }
}

// MARK: - 2x2 Small Tangerine Widget

struct SmallWidgetView: View {
  let entry: AeroEntry
  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack {
        Text("AEROSTEP").font(.system(size: 10, weight: .bold)).foregroundColor(.white.opacity(0.8))
        Spacer()
        StepRing(progress: entry.progress).frame(width: 40, height: 40)
      }
      Spacer(minLength: 0)
      Text(formatted(entry.steps))
        .font(.system(size: 30, weight: .bold, design: .rounded))
        .monospacedDigit()
        .foregroundColor(.white)
        .minimumScaleFactor(0.6)
      Text("/ \(formatted(entry.goal)) steps")
        .font(.system(size: 12, weight: .medium))
        .foregroundColor(.white.opacity(0.9))
    }
    .padding(14)
    .aeroBackground(LinearGradient(colors: [tangerine, tangerineLight], startPoint: .topLeading, endPoint: .bottomTrailing))
  }
}

struct AeroStepSmallWidget: Widget {
  let kind = "AeroStepSmallWidget"
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: AeroProvider()) { SmallWidgetView(entry: $0) }
      .configurationDisplayName("AeroStep Steps")
      .description("Today's steps and goal ring.")
      .supportedFamilies([.systemSmall])
  }
}

// MARK: - 4x2 Medium Bento Widget

struct BentoWidgetView: View {
  let entry: AeroEntry
  var body: some View {
    HStack(spacing: 10) {
      VStack(alignment: .leading, spacing: 2) {
        Text("TODAY").font(.system(size: 10, weight: .bold)).foregroundColor(.white.opacity(0.8))
        Text(formatted(entry.steps))
          .font(.system(size: 26, weight: .bold, design: .rounded))
          .monospacedDigit()
          .foregroundColor(.white)
          .minimumScaleFactor(0.6)
        Text("/ \(formatted(entry.goal))").font(.system(size: 11)).foregroundColor(.white.opacity(0.9))
        Spacer(minLength: 0)
        ProgressView(value: entry.progress).tint(.white)
      }
      .padding(12)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
      .background(LinearGradient(colors: [tangerine, tangerineLight], startPoint: .topLeading, endPoint: .bottomTrailing))
      .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

      VStack(spacing: 6) {
        Text("\(entry.kcal) kcal")
          .font(.system(size: 13, weight: .bold)).monospacedDigit()
          .foregroundColor(.white)
          .frame(maxWidth: .infinity).padding(.vertical, 6)
          .background(Capsule().fill(charcoal))
        Text("\(entry.cadence) SPM")
          .font(.system(size: 13, weight: .bold)).monospacedDigit()
          .foregroundColor(charcoal)
        Spacer(minLength: 0)
        Text(String(format: "%.2f / 2.5 L", Double(entry.hydrationMl) / 1000))
          .font(.system(size: 12, weight: .bold)).monospacedDigit()
          .foregroundColor(Color(red: 0, green: 0.404, blue: 0.51))
        WaterButton()
      }
      .frame(maxWidth: .infinity)
    }
    .padding(12)
    .aeroBackground(LinearGradient(colors: [peachTop, peachBottom], startPoint: .top, endPoint: .bottom))
  }
}

/// Interactive +250 ml tap (iOS 17+). Older iOS opens the app instead.
struct WaterButton: View {
  var body: some View {
    if #available(iOSApplicationExtension 17.0, *) {
      Button(intent: AddWaterIntent()) { label }.buttonStyle(.plain)
    } else {
      Link(destination: URL(string: "aerostep://water?ml=250")!) { label }
    }
  }

  private var label: some View {
    Text("+250ml")
      .font(.system(size: 13, weight: .bold))
      .foregroundColor(Color(red: 0, green: 0.122, blue: 0.161))
      .frame(maxWidth: .infinity).padding(.vertical, 6)
      .background(Capsule().fill(skyCyan))
  }
}

struct AeroStepBentoWidget: Widget {
  let kind = "AeroStepBentoWidget"
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: AeroProvider()) { BentoWidgetView(entry: $0) }
      .configurationDisplayName("AeroStep Bento")
      .description("Steps, calories, cadence and 1-tap water logging.")
      .supportedFamilies([.systemMedium])
  }
}

extension View {
  @ViewBuilder
  func aeroBackground<B: View>(_ background: B) -> some View {
    if #available(iOSApplicationExtension 17.0, *) {
      self.containerBackground(for: .widget) { background }
    } else {
      self.background(background)
    }
  }
}

@main
struct AeroStepWidgetBundle: WidgetBundle {
  var body: some Widget {
    AeroStepSmallWidget()
    AeroStepBentoWidget()
  }
}
