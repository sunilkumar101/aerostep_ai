# AeroStep iOS — finishing on a Mac

The Flutter app, Info.plist, Podfile (iOS 15), HealthKit + App Group entitlements and
WidgetKit Swift sources are all in this repo. Two steps need Xcode on macOS because a
widget extension target cannot be created reliably by hand-editing `project.pbxproj`:

## 1. Add the WidgetKit extension target (one time, ~2 minutes)
1. `flutter pub get && cd ios && pod install`, then open `ios/Runner.xcworkspace`.
2. File > New > Target > **Widget Extension**. Product name `AeroStepWidget`,
   bundle id `com.sunilkhatri.aerostep.AeroStepWidget`, untick "Include Configuration App Intent".
3. Delete the Swift files Xcode generated and add the existing files from `ios/AeroStepWidget/`
   (`AeroStepWidget.swift`, `AddWaterIntent.swift`, `Info.plist`) to the new target.
4. Target **AeroStepWidget** > Build Settings: `CODE_SIGN_ENTITLEMENTS = AeroStepWidget/AeroStepWidget.entitlements`,
   iOS Deployment Target `15.0`.
5. Signing & Capabilities: enable **App Groups** `group.com.sunilkhatri.aerostep` on both
   **Runner** and **AeroStepWidget**; enable **HealthKit** (+ Background Delivery) on Runner.
6. Runner > Build Phases: move "Embed Foundation Extensions" above "Run Script (Thin Binary)".

## 2. Verify
```bash
flutter build ios --config-only --no-codesign
flutter build ios --no-codesign
```

## Release ids
- Replace `ADMOB_APP_ID` in `ios/Flutter/Release.xcconfig` with the real AdMob iOS app id.
- Build with `--dart-define=ADMOB_REWARDED_IOS=<real rewarded unit id>`.

App Store submission is intentionally **not** part of this build.
