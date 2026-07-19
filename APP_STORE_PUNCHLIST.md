# App Store Punch List

## Local Validation Completed (July 19, 2026)

- Xcode 26.6 / iOS 26.5 simulator runtime installed and used successfully.
- All active unit and integration tests pass.
- All 10 functional UI scenarios and all 4 launch configurations pass on iPhone 17 Pro.
- The 10 functional UI scenarios also pass on iPhone 17e and iPad mini.
- Release builds succeed for both the generic iOS Simulator and generic iOS device destinations.
- Apple Developer signing is configured. A signed archive and App Store Connect `.ipa` export both succeed; the distribution profile is valid through July 16, 2027.
- Xcode static analysis succeeds with no source-code diagnostics. Xcode emits only its harmless App Intents metadata-skipped message because Mira does not link AppIntents.
- The Release bundle contains `PrivacyInfo.xcprivacy`, declares no tracking, and contains no provider credential.

## Ship Blockers

- Publish and verify the privacy, support, and terms pages, then add the live URLs to the bundled release configuration and regenerate the final signed archive.
- Keep release URLs in the ignored `Mira/Resources/Configuration.plist`; never place provider secrets in an App Store binary. Use a controlled backend before relying on a private USDA key at production scale.
- Add a real privacy policy URL, support URL, and terms URL before submission.
- Verify barcode and on-device photo-label scanning end to end on physical devices.
- Run physical-device QA on at least one small iPhone, one standard iPhone, one large iPhone, and an iPad in portrait and landscape with the signed Release build. Simulator coverage now includes iPhone 17e, iPhone 17 Pro, and iPad mini; alternatively, explicitly scope 1.0 to iPhone before submission.

## High Priority

- Verify the deterministic photo-result and disambiguation flows with real photos on a physical device. Xcode UI tests now pass for onboarding, simulated barcode scan to detail, denied camera permission with search fallback, photo-scan entry, single-match confirmation, multiple-match disambiguation, seeded history/detail, shopping list, clearing history, and full local-data reset.
- Verify App Store metadata:
  - screenshots
  - privacy nutrition labels
  - age rating
  - app description and keywords
- Complete the current App Store Connect age-rating questionnaire and EU trader-status declaration if distributing in the EU.
- Profile launch time and first-scan latency on a real device.
- Audit VoiceOver labels and Dynamic Type on scanner, product detail, and insights.

## Better Than Yuka

- Make every score explainable with specific evidence, not just a verdict.
- Push alternatives harder:
  - faster loading
  - stronger match quality
  - clearer reasons why the replacement is better
- Treat personalization as a core differentiator:
  - health focus should visibly change recommendations
  - dietary restrictions should affect ranking, not just warnings
- Improve trust:
  - show data source provenance
  - show confidence and fallback behavior for AI-assisted features
  - avoid claiming precision where the data is incomplete
- Improve retention:
  - weekly insights should feel useful after 5 to 10 scans
  - history should surface patterns, not just a list of old scans

## Competitive Baseline Now Present

- Barcode scan, text search, history, color-coded score, score explanation, ingredient flags, and healthier alternatives.
- Dietary-restriction and health-focus personalization, side-by-side comparison, favorites, shopping list, and pattern insights.
- On-device photo-label OCR fallback, offline essentials catalog, and visible source provenance with a package-label verification reminder.

## Competitive Gaps to Validate or Plan

- Yuka-scale catalog coverage, product freshness controls, and stronger alternative availability/ranking need production metrics and editorial operations, not just client code.
- Scientific citations should be visible for every additive/ingredient claim before marketing Mira as research-backed.
- Cosmetics/personal-care scanning and verified organic-certification scoring are not part of the 1.0 food-only scope.
- Store-specific product browsing, highlighted ingredient drill-down depth, and offline scanning breadth trail the current Bobby Approved/Yuka listings.

## Deferred Until After 1.0

- Notification settings
- appearance customization
- text size controls beyond system Dynamic Type
- iCloud sync
