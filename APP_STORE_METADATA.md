# Mira 1.0 App Store Metadata Draft

Replace every bracketed value and verify the final text in App Store Connect before submission.

## Product Page

**Name (30 characters maximum)**<br>
Mira: Smart Food Scanner

**Subtitle (30 characters maximum)**<br>
Personalized grocery insights

**Primary category**<br>
Food & Drink

**Secondary category**<br>
Health & Fitness

**Promotional text (170 characters maximum)**<br>
Scan or search foods, understand the score, compare options, and find choices that better fit your nutrition goals and dietary preferences.

**Keywords (100 bytes maximum; do not add competitor names)**<br>
nutrition,barcode,ingredients,grocery,food,scanner,diet,shopping,additives,compare,wellness

**Description**

Mira helps make food labels easier to understand while you shop.

Scan a barcode or search by name to see a clear health score, nutrition details, ingredient insights, processing information, and practical alternatives. Mira can personalize results around your health focus and saved dietary preferences without requiring an account.

WHAT YOU CAN DO

• Scan packaged-food barcodes for fast product details<br>
• Photograph a product label and identify it with on-device text recognition<br>
• Search naturally, such as “high-protein snacks” or “low-sugar cereal”<br>
• Understand the factors behind each score<br>
• Review ingredient and dietary-restriction warnings<br>
• Compare products side by side<br>
• Discover potentially better alternatives<br>
• Save favorites and build a shopping list<br>
• See patterns across your scan history<br>
• Use a bundled essentials catalog when connectivity is limited

BUILT FOR TRANSPARENCY

Mira identifies the source of product data and reminds you to verify the current package label. Product formulations and public databases can change.

PRIVACY BY DESIGN

Mira has no account, advertising, or cross-app tracking. Personal preferences, history, favorites, shopping-list items, and diagnostics remain on the device. App Store builds process product-photo text on the device.

Mira provides general food and nutrition information, not medical advice. Always verify package and allergen labels. Consult a qualified healthcare professional for personal medical guidance.

Product information is supported by Open Food Facts and USDA FoodData Central.

## Required URLs

- Privacy policy: `https://lbarnhart.github.io/Mira8/privacy/`
- Support URL with real contact information: `https://lbarnhart.github.io/Mira8/support/`
- Marketing URL, optional: `https://lbarnhart.github.io/Mira8/`
- Terms URL for the in-app About screen: `https://lbarnhart.github.io/Mira8/terms/`

## App Review Information

**Sign-in required:** No<br>
**Demo account:** Not applicable

**Review notes draft**

Mira does not require an account or subscription. The Scan tab requests camera access for live barcode scanning. Reviewers may also use Search without granting camera access.

Suggested barcode for live testing: `5449000000996` (availability depends on the current public product databases). Product-photo recognition is available from the Photo control on the Scan tab and runs on device in the App Store build. An internet connection improves product coverage; a bundled catalog supplies limited offline results.

The health score is informational and its contributing factors are visible on the product-detail screen. The About screen contains the health disclaimer, privacy summary, support links, and data-source attribution. Settings includes Clear Scan History and Reset All App Data controls.

Review contact:

- Name: `Lauren Barnhart`
- Phone: `[REVIEW_CONTACT_PHONE]`
- Email: `barnhartl91@gmail.com`

## Screenshot Set

The reproducible Release screenshot suite produces matching 6.9-inch iPhone and 13-inch iPad sets with fictitious, rights-safe product data:

1. Product overview and explainable score
2. Personalized health-focus comparison
3. Weekly nutrition insights
4. Scan history
5. Shopping list

Generate the final files with `scripts/capture_app_store_screenshots.sh` after the release source is frozen, then upload and verify them in App Store Connect.

## Submission Answers Requiring Owner Verification

- Confirm App Privacy answers against the current Open Food Facts and USDA privacy practices, including whether request logs meet Apple's definition of collection.
- Complete the current age-rating questionnaire; do not characterize Mira as providing diagnosis or treatment.
- Confirm export compliance remains “no non-exempt encryption” for the submitted binary.
- Declare EU trader status if the app will be available in the European Union.
- Verify content rights for every screenshot, logo, product image, and store-listing statement.
