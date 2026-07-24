---
layout: page
title: How Mira Scores Products
permalink: /methodology/
---

# How Mira Scores Products

Mira’s score is a decision aid, not an objective definition of whether a food is “good” or “bad.” It summarizes the available product record through a selected health lens and shows the most important reasons behind the result.

The current scoring contract is **health-scoring-v1.2.0**.

## What the score uses

Mira normalizes available nutrition values to a consistent 100 g or 100 mL basis, then evaluates four bounded areas:

- sugar
- sodium
- energy and saturated fat
- positive nutrition, including fiber, protein, and estimated fruit, vegetable, legume, and nut content

For the General Wellness lens, those areas receive 30%, 20%, 25%, and 25% of the available weight, respectively. Other health lenses change the relative weights. Category and beverage rules can also adjust thresholds so unlike foods are not treated as identical.

Ingredient-based guardrails may cap a score when the available ingredient list indicates refined oils, non-nutritive sweeteners, ultra-processed markers, extreme nutrient levels, or a conflict with the user’s selected dietary restrictions.

## Missing or uncertain data

Mira does not silently treat an unknown nutrient as zero. If a scoring area lacks enough information, that area is dropped and the remaining available weights are normalized. The app lowers its confidence, identifies missing fields, and may limit the score’s range.

Public product databases and package formulations can be incomplete, inaccurate, or out of date. Mira displays the source used for the product record and asks users to verify important information against the current package label.

## Data sources

Mira may use:

- [Open Food Facts](https://world.openfoodfacts.org/) for community-maintained barcode, ingredient, and nutrition records
- [USDA FoodData Central](https://fdc.nal.usda.gov/) when that service is securely configured and an appropriate product record is available
- a small bundled Mira catalog for limited offline results

Open Food Facts expressly notes that its volunteer-provided data may not be accurate, complete, or reliable. USDA branded-food nutrition is generally derived from manufacturer label information rather than independent laboratory testing.

## What users can inspect

Inside **See how Mira calculated this**, users can review:

- the nutrient score before other rules
- any rule or data-confidence effect
- the final score
- every positive and negative nutrient contribution
- ingredient or dietary guardrails
- missing fields and confidence
- the product-data source
- the scoring, weight-profile, and threshold-set versions

This detail is intentionally optional so the main product screen remains quick to understand.

## Important limits

Mira provides general food and nutrition information, not medical advice. The score does not account for an individual’s complete diet, portion frequency, medical history, or every possible food-quality consideration. Reasonable people with different priorities may disagree with the score.

Questions or methodology feedback: **barnhartl91@gmail.com**
