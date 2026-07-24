# App Store Connect Submission Guide

Prepared for Mira 1.0 (build 1), bundle ID `com.mira8.app`. Record the final commit and regenerated artifact below after the current barcode-only release candidate passes validation.

This guide records recommended answers based on the reviewed Release binary and source. Recheck it if the app's services, business model, or data practices change.

## Build and URLs

- App name: **Mira**
- Version: **1.0**
- Build: **1**
- Primary category: **Health & Fitness**
- Secondary category: **Food & Drink**
- Privacy policy: <https://lbarnhart.github.io/Mira8/privacy/>
- Terms of use: <https://lbarnhart.github.io/Mira8/terms/>
- Support URL: <https://lbarnhart.github.io/Mira8/support/>
- Marketing URL: <https://lbarnhart.github.io/Mira8/>
- Scoring methodology: <https://lbarnhart.github.io/Mira8/methodology/>
- Support email: **barnhartl91@gmail.com**
- Copyright: **2026 Lauren Barnhart**

Do not upload the previous v1.2 artifact; it predates removal of photo scanning and the revised score explanation. Fill these fields from the regenerated, audited release candidate:

- Commit: **Pending**
- IPA: **Pending**
- SHA-256: **Pending**
- Scoring contract: `health-scoring-v1.2.0`

## App Privacy

Recommended conservative disclosure:

- Select **Yes, we collect data from this app**.
- Declare **Search History**.
  - Purpose: **App Functionality**.
  - Linked to the user's identity: **No**.
  - Used for tracking: **No**.
- Do not declare camera data, health-profile preferences, scan history, favorites, shopping-list data, diagnostics, or identifiers as collected by Mira. These remain on-device in the reviewed Release build.

Why this is conservative: searches and scans send a barcode, product name, brand, or search terms to Open Food Facts and/or USDA FoodData Central. Those providers also receive ordinary network metadata. Apple defines Search History as searches performed in an app and requires third-party partner practices to be included. The public privacy policy already describes these requests.

Before saving, confirm that Open Food Facts and USDA do not use Mira request data for tracking or link it to a user identity. If their current retention practices establish that the query and IP address are discarded immediately after servicing each request, Apple's definition may permit **Data Not Collected** instead. Do not choose that less conservative answer without documenting the providers' current retention terms.

Not present in the reviewed Release build:

- Accounts or authentication
- Advertising or advertising identifier access
- Cross-app tracking
- Analytics or crash-reporting SDKs
- Purchases or subscriptions
- Photo-library access or image recognition
- A configured Claude/Anthropic credential or production AI request path

## Age Rating

Recommended questionnaire answers:

- **Health or Wellness Topics: Yes**.
- **Medical or Treatment Information: None**. Mira provides general nutrition and food-choice information, includes a visible medical disclaimer, and does not diagnose, treat, or manage a medical condition.
- All violence, sexual content, profanity, horror, alcohol/tobacco/drug references, gambling, contests, loot boxes, unrestricted web access, user-generated content, messaging/chat, social media, and advertising: **None/No**.
- Parental controls and age assurance: **No**.

Expected Apple global rating: **9+**, because the app contains health and wellness topics. Accept App Store Connect's calculated regional ratings rather than overriding them unless the questionnaire shown by Apple differs materially from the reviewed app.

## Export Compliance

- Does the app use encryption? **Yes**, only through Apple's operating-system networking for HTTPS.
- Does the app implement proprietary or non-standard encryption? **No**.
- Does the app implement standard encryption algorithms itself, rather than only using Apple's OS? **No**.
- Exempt from documentation: **Yes**.

The built app declares `ITSAppUsesNonExemptEncryption = false`. No export-compliance document is expected for this configuration.

## Content Rights

- Does the app contain, show, or access third-party content? **Yes**.
- Does the app have the necessary rights? **Yes**, based on the reviewed uses:
  - USDA FoodData Central data is US government/public-domain material.
  - Open Food Facts content is used under its published database/content licenses and is attributed in the app.
  - Product and brand names are presented as factual identification; the app does not claim ownership of third-party marks.

Keep source attribution visible and preserve any license notices required by the data providers.

## Advertising, Commerce, and Access

- Advertising: **None**.
- In-app purchases/subscriptions: **None**.
- Sign-in required: **No**.
- App Review demo account: **Not required**.
- Regulated medical device: **No**.

Suggested App Review note:

> Mira is a food-information app with no account or paywall. Live barcode scanning requires camera permission and a physical device. Search can be used without camera access. Product data comes from Open Food Facts, USDA FoodData Central, or the bundled offline catalog. Mira provides general nutrition information, not medical advice. Settings includes Clear Scan History and Reset All App Data.

## Availability and Release

Recommended initial release settings:

- Price: **Free**.
- Distribution: make available in the countries/regions where the developer is prepared to provide support and satisfy local compliance requirements.
- Release option: **Manually release this version**. This provides a final control point after approval.
- Mac availability for iPhone/iPad apps: disable for 1.0 unless it is explicitly tested and supported.
- Apple Vision Pro availability: disable for 1.0 unless it is explicitly tested and supported.

## Owner-Only Decisions and Missing Values

These cannot be truthfully completed from the codebase:

- **App Review phone number:** provide a working number where Apple can reach Lauren during review.
- **EU Digital Services Act trader status:** Lauren must make the legal/business-status declaration. If Mira is offered as part of commercial or professional activity, select trader and provide the required public contact details. If it is a genuinely non-commercial hobby project, non-trader may be appropriate. Apple explicitly says it cannot determine this status for the developer.
- **Countries/regions:** choose based on the intended launch and support footprint.
- **Automatic vs manual release:** the recommendation above is manual, but this remains an owner decision.
- **iPad physical-device risk acceptance:** either complete real-device iPad QA or explicitly accept the risk for 1.0.

## Final Submission Order

1. Complete physical-iPhone Release QA and record the device/iOS version and result.
2. Resolve the iPad physical-device test or risk-acceptance decision.
3. Enter the privacy, age-rating, export-compliance, content-rights, and DSA answers.
4. Upload the regenerated signed build and wait for processing.
5. Attach the five iPhone 6.9-inch and five iPad 13-inch screenshots.
6. Add the App Review contact phone number and review note.
7. Select build 1, verify metadata and URLs, then submit for review.
