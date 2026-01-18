#!/usr/bin/env python3
"""
Generate essentials_catalog.json from OpenFoodFacts CSV data dump.

Usage:
    1. Download the US products CSV from OpenFoodFacts:
       https://world.openfoodfacts.org/data
       (Look for "en.openfoodfacts.org.products.csv" or the US-specific dump)

    2. Run this script:
       python3 generate_essentials_catalog.py path/to/products.csv --output ../Mira/Resources/essentials_catalog.json

    3. The script will filter to US products and select the top 5000 by scan count.
"""

import csv
import gzip
import json
import argparse
import sys
from datetime import datetime, timezone
from typing import Optional, Dict, Any, List

# Increase CSV field size limit for OpenFoodFacts data (some fields are very large)
csv.field_size_limit(sys.maxsize)


def parse_nutrition_value(value: str) -> float:
    """Parse a nutrition value, handling empty/invalid values."""
    if not value or value.strip() == '':
        return 0.0
    try:
        # Remove units if present (e.g., "10 g" -> "10")
        cleaned = value.split()[0] if ' ' in value else value
        return float(cleaned)
    except (ValueError, IndexError):
        return 0.0


def parse_ingredients(ingredients_text: str) -> List[str]:
    """Parse ingredients text into a list."""
    if not ingredients_text or ingredients_text.strip() == '':
        return []

    # Split by common separators
    ingredients = []
    for sep in [', ', '; ', ' - ']:
        if sep in ingredients_text:
            parts = ingredients_text.split(sep)
            ingredients = [i.strip().lower() for i in parts if i.strip()]
            break

    if not ingredients:
        ingredients = [ingredients_text.strip().lower()]

    return ingredients[:20]  # Limit to first 20 ingredients


def process_product(row: Dict[str, str]) -> Optional[Dict[str, Any]]:
    """Process a single product row into our format."""
    barcode = row.get('code', '').strip()
    name = row.get('product_name', '').strip()

    # Skip products without barcode or name
    if not barcode or not name or len(barcode) < 8:
        return None

    # Get nutrition data (per 100g)
    nutrition = {
        'calories': parse_nutrition_value(row.get('energy-kcal_100g', '')),
        'protein': parse_nutrition_value(row.get('proteins_100g', '')),
        'carbohydrates': parse_nutrition_value(row.get('carbohydrates_100g', '')),
        'fat': parse_nutrition_value(row.get('fat_100g', '')),
        'saturatedFat': parse_nutrition_value(row.get('saturated-fat_100g', '')),
        'fiber': parse_nutrition_value(row.get('fiber_100g', '')),
        'sugar': parse_nutrition_value(row.get('sugars_100g', '')),
        'sodium': parse_nutrition_value(row.get('sodium_100g', '')) / 1000  # Convert mg to g
    }

    # Skip products with no nutrition data
    if nutrition['calories'] == 0 and nutrition['protein'] == 0 and nutrition['carbohydrates'] == 0:
        return None

    brand = row.get('brands', '').strip() or None
    category = row.get('categories_en', '').split(',')[0].strip() if row.get('categories_en') else 'other'
    serving_size = row.get('serving_size', '').strip() or None
    ingredients = parse_ingredients(row.get('ingredients_text', ''))

    return {
        'barcode': barcode,
        'name': name,
        'brand': brand,
        'category': category.lower(),
        'nutrition': nutrition,
        'servingSize': serving_size,
        'ingredients': ingredients if ingredients else None
    }


def main():
    parser = argparse.ArgumentParser(description='Generate essentials catalog from OpenFoodFacts data')
    parser.add_argument('input_file', help='Path to OpenFoodFacts CSV file')
    parser.add_argument('--output', '-o', default='essentials_catalog.json', help='Output JSON file path')
    parser.add_argument('--limit', '-l', type=int, default=5000, help='Maximum number of products')
    args = parser.parse_args()

    print(f"Reading {args.input_file}...")

    products = []
    skipped = 0

    # Handle both .csv and .csv.gz files
    if args.input_file.endswith('.gz'):
        file_handle = gzip.open(args.input_file, 'rt', encoding='utf-8', errors='replace')
    else:
        file_handle = open(args.input_file, 'r', encoding='utf-8', errors='replace')

    with file_handle as f:
        reader = csv.DictReader(f, delimiter='\t')

        for row in reader:
            # Filter to US products
            countries = row.get('countries_tags', '').lower()
            if 'united-states' not in countries and 'en:united-states' not in countries:
                continue

            product = process_product(row)
            if product:
                # Get scan count for sorting
                try:
                    scans = int(row.get('unique_scans_n', '0') or '0')
                except ValueError:
                    scans = 0
                products.append((scans, product))
            else:
                skipped += 1

    print(f"Found {len(products)} valid US products, skipped {skipped}")

    # Sort by scan count (descending) and take top N
    products.sort(key=lambda x: x[0], reverse=True)
    top_products = [p[1] for p in products[:args.limit]]

    print(f"Selected top {len(top_products)} products by scan count")

    # Create catalog
    catalog = {
        'version': '1.0.0',
        'generatedAt': datetime.now(timezone.utc).isoformat(),
        'productCount': len(top_products),
        'products': top_products
    }

    # Write output
    with open(args.output, 'w', encoding='utf-8') as f:
        json.dump(catalog, f, indent=2, ensure_ascii=False)

    print(f"Wrote catalog to {args.output}")
    print(f"File size: {len(json.dumps(catalog)) / 1024:.1f} KB")


if __name__ == '__main__':
    main()
