# App Store Punch List

## Ship Blockers

- Restore a reproducible Xcode project or workspace in the repo and verify a clean Release build.
- Rotate the previously committed USDA key and keep all secrets in `App/Configuration/Configuration.plist`.
- Add a real privacy policy URL, support URL, and terms URL before submission.
- Decide the 1.0 feature surface explicitly:
  - Keep barcode scanning, scoring, history, insights, shopping list, and product detail.
  - Ship photo scan only when `ClaudeAPIKey` is configured and the flow is tested end to end.
- Run device QA on at least one small iPhone, one standard iPhone, and one large iPhone with the release build.

## High Priority

- Add UI tests for onboarding, barcode scan to detail, denied camera permission, history, and shopping list.
- Remove or replace remaining placeholder UI and debug-only behavior in production-facing flows.
- Verify App Store metadata:
  - screenshots
  - privacy nutrition labels
  - age rating
  - app description and keywords
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

## Deferred Until After 1.0

- Notification settings
- appearance customization
- text size controls beyond system Dynamic Type
- iCloud sync
