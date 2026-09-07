# App Store Punch List

## Local Validation Completed (July 26, 2026)

- Xcode 26.6 / iOS 26.5 simulator runtime installed and used successfully.
- The full serial regression suite passes: 65 tests passed, 16 intentionally superseded scoring-contract tests skipped, and 0 tests failed.
- All 7 barcode-only functional UI scenarios and all 4 launch configurations pass on iPhone 17 Pro.
- All 7 barcode-only functional UI scenarios also pass on iPhone 17e and iPad mini.
- Automated accessibility audits pass on iPhone 17e and iPad mini across contrast, element detection, hit regions, descriptions, clipping, traits, and Dynamic Type.
- Release builds succeed for both the generic iOS Simulator and generic iOS device destinations.
- Apple Developer signing is configured, and the distribution profile is valid through July 16, 2027.
- The barcode-only v1.5 IPA was archived from app-source commit `c44113310aeb2ce57a62296fad9cf4cb03bb25e5` and passes strict signature, distribution-entitlement, privacy-manifest, public-URL, photo-permission, removed-feature-claim, tracking, bundled-review-barcode, and credential audits. Its SHA-256 is `c9ac69c60349cf7f390ee2114ec333f3f753408a2ed2bb69232e522099752d00`.
- Xcode static analysis succeeds with no source-code diagnostics. Xcode emits only its harmless App Intents metadata-skipped message because Mira does not link AppIntents.
- The Release bundle contains `PrivacyInfo.xcprivacy`, declares no tracking, and contains no provider credential.
- The privacy, terms, support, and marketing pages are public on GitHub Pages, return HTTP 200, and their live URLs are present in the release configuration.
- The public scoring-methodology page is deployed from `gh-pages`, returns HTTP 200, and identifies the active `health-scoring-v1.2.0` contract.
- Deterministic, rights-safe App Store screenshot tests generate five verified 6.9-inch iPhone images and five verified 13-inch iPad images in accepted pixel dimensions.
- The bounded scoring contract is versioned as `health-scoring-v1.2.0`; representative-food and nutrient-availability regression tests cover the corrected weight normalization and known-zero handling.
- The App Store description, privacy copy, review notes, and in-app About summary consistently describe the barcode-and-search experience; no customer-facing copy advertises the removed photo-recognition feature.

## Ship Blockers

- Keep release URLs in the ignored `Mira/Resources/Configuration.plist`; never place provider secrets in an App Store binary. Use a controlled backend before relying on a private USDA key at production scale.
- Verify barcode scanning end to end on physical devices. Camera permission and a real packaged-food barcode have passed on the connected iPhone.
- Complete signed Release-build QA on at least one physical iPhone, including offline fallback and data reset. The paired iPhone 17 Pro runs iOS 26.5.2 with Developer Mode enabled, but currently has no device tunnel and must be connected and unlocked before installation. Simulator validation covers small/standard/large iPhone and iPad layouts; test a physical iPad too if one is available, or make an explicit risk acceptance for 1.0.
- Supply the App Review contact phone number and complete the App Store Connect privacy, age-rating, export-compliance, EU trader-status, and content-rights declarations.
- Complete the regulated-medical-device declaration shown for Health & Fitness apps; Mira's documented answer is **No**.

Submission field recommendations and the remaining owner-only decisions are recorded in `APP_STORE_CONNECT_SUBMISSION.md`.

## High Priority

- Keep the barcode-only scanner regression suite green. Xcode UI tests cover onboarding, simulated barcode scan to detail, denied camera permission with search fallback, seeded history/detail, shopping list, clearing history, and full local-data reset.
- Keep score detail optional: the product page shows a verdict and two plain-language reasons, while calculation, provenance, confidence, missing fields, and scoring-version details remain available under **Why this score?**
- Upload and verify the generated screenshots and metadata in App Store Connect.
- Complete the current App Store Connect age-rating questionnaire and EU trader-status declaration if distributing in the EU.
- Profile launch time and first-scan latency on a real device.
- Complete a short VoiceOver smoke test on the signed physical-device build. Automated label, trait, hit-region, contrast, clipping, and Dynamic Type audits already pass on compact iPhone and iPad layouts.

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
- Offline essentials catalog and visible source provenance with a package-label verification reminder.

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
