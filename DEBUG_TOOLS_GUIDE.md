# 🔧 Scan History Debug Tools Guide

## Overview

A comprehensive debug toolkit has been added to help diagnose why ingredients from your scan history are showing as "NEEDS DEFINITION - TELL LAUREN".

## How to Access the Debug Tools

1. **Build in DEBUG mode** (Xcode's default debug configuration)
2. **Navigate to History tab**
3. **Look for the wrench icon (🔧)** in the top-right toolbar
4. **Tap it to see debug options**

## Available Debug Functions

### 1. **Scan History Debug** 🔍
**Location:** Menu → Scan History Debug

**What it does:**
- Analyzes ALL products in your scan history
- For each product, displays:
  - Product name, barcode, brand, category
  - Whether ingredients are stored
  - Number and category breakdown of ingredients
  - Which ingredients are missing definitions
  - Sample ingredients from each product

**Output includes:**
- ✅ Products WITH ingredients
- ❌ Products WITHOUT ingredients  
- 📊 Ingredient analysis breakdown
  - Beneficial count
  - Neutral count
  - Concerning count
  - Unknown/Missing count

**Summary statistics:**
- Total products scanned
- Total unique ingredients
- Top 20 most common ingredients across all scans

**Look for in console:**
```
🔍 SCAN HISTORY INGREDIENT DEBUG REPORT
Product: [Product Name]
✅ INGREDIENTS FIELD: [count parsed]
   Missing Definitions:
      - ingredient1
      - ingredient2
📈 SUMMARY STATISTICS
Total unique ingredients: XXX
Top 20 Most Common Ingredients:
1. ingredient (N occurrences)
```

---

### 2. **Ingredient Analyzer Database Debug** 🔬
**Location:** Menu → Analyzer Database Debug

**What it does:**
- Tests 15 common ingredients against the analyzer
- Shows if each ingredient is found in the database
- Displays the category and explanation for each

**Test ingredients:**
- salt, sugar, wheat flour, water, corn syrup
- soybean oil, corn starch, yeast, baking powder
- vanilla extract, citric acid, sodium benzoate
- high fructose corn syrup, artificial flavor, trans fat

**Output shows:**
```
✅ Beneficial ingredients
⚪ Neutral ingredients
⚠️ Concerning ingredients
❓ Unknown/Missing ingredients
```

**Example output:**
```
⚪ salt
   → Salt
   → Common mineral used to preserve and season.

❓ artificial flavor
   → Artificial Flavor
   → NEEDS DEFINITION - TELL LAUREN
```

---

## How to Interpret the Results

### Scenario 1: "All ingredients showing as NEEDS DEFINITION"

**Possible causes:**
1. ❌ Ingredients aren't being stored in CoreData
2. ❌ Ingredients are stored but not being parsed correctly
3. ❌ Ingredients are being parsed but don't match database entries

**How to debug:**
1. Run "Scan History Debug"
2. Check: Are products showing `✅ INGREDIENTS FIELD` or `❌ INGREDIENTS FIELD: EMPTY or NIL`?
3. If EMPTY → Ingredients aren't being saved
4. If ingredients exist → Run "Analyzer Database Debug" to check if common ingredients are found

---

### Scenario 2: "Some ingredients missing definitions"

**Possible causes:**
1. The ingredient name doesn't match the database exactly
   - Example: Database has "salt" but product says "sea salt"
2. The ingredient is new and wasn't in the original 1,016-item database
3. Parsing issue: Extra spaces, punctuation, or formatting

**How to debug:**
1. Note the exact ingredient name showing as "NEEDS DEFINITION"
2. Run "Analyzer Database Debug" with similar ingredients
3. Consider adding the missing ingredient to IngredientAnalyzer.buildIngredientDatabase()

---

## Common Debug Patterns

### ✅ Everything is working
```
✅ INGREDIENTS FIELD:
   Parsed Count: 8
   📊 INGREDIENT ANALYSIS:
   Total Analyzed: 8
   Beneficial: 2
   Neutral: 5
   Concerning: 1
   Unknown/Missing: 0
```

### ⚠️ Ingredients are empty
```
❌ INGREDIENTS FIELD: EMPTY or NIL

[No ingredients to analyze]
```

### ⚠️ Many ingredients missing from database
```
📊 INGREDIENT ANALYSIS:
   Total Analyzed: 12
   Unknown/Missing: 8
```

---

## What to Try Next

Based on your debug findings:

### If ingredients aren't being saved:
- Check if API calls include ingredients
- Verify CoreData schema
- Look for parsing errors during save

### If ingredients are stored but not matching:
- Add missing common ingredients to database
- Improve ingredient name normalization
- Add fuzzy matching for similar names

### If database test shows gaps:
- The 1,016-item database may not cover all products
- Need to update with new ingredients found in user scans

---

## Technical Details

### Where the debug code lives:
- **Debug functions:** `Mira/Features/History/ViewModels/HistoryViewModel.swift`
- **Debug toolbar:** `Mira/Features/History/Views/HistoryView.swift` (wrapped in `#if DEBUG`)
- **Ingredient Analyzer:** `Mira/Core/Utils/IngredientAnalyzer.swift`

### How it works:
1. Fetches all `ScanHistoryEntity` records from CoreData
2. For each product, retrieves the stored ingredients string
3. Parses the comma-separated string into individual ingredients
4. Analyzes each using `IngredientAnalyzer.shared.analyze()`
5. Categorizes results and prints formatted report

### Console output location:
- Open Xcode → Product → Scheme → Edit Scheme
- Set "Run" configuration to "Debug"
- Build and run
- View console with Cmd+Shift+Y
- Scroll down to find 🔍 reports

---

## Pro Tips

💡 **Tip 1: Save console output**
- Select all console text (Cmd+A)
- Copy (Cmd+C)
- Paste into a text file for analysis

💡 **Tip 2: Run after scanning new products**
- Scan a few products
- Run "Scan History Debug" immediately
- See which ingredients need adding

💡 **Tip 3: Cross-reference with CSVs**
- Export scan results
- Compare against ingredient_database_export.csv
- Identify missing ingredients

---

## Questions This Tool Answers

- ✅ "Are ingredients being stored in CoreData?"
- ✅ "How many products have ingredient data?"
- ✅ "What are my most common scanned ingredients?"
- ✅ "Which ingredients are missing definitions?"
- ✅ "Is the analyzer database working?"
- ✅ "How many ingredients from test set are recognized?"

---

## Need Help?

If debug output is unclear:
1. Take a screenshot of console output
2. Note the product names/barcodes showing issues
3. Check if it's a parsing issue or database gap
4. Consider expanding the ingredient database

