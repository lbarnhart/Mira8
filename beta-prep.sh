#!/bin/bash
# Mira 8 Beta Prep Script

echo "🚀 Preparing Mira 8 for Beta Testing"

# 1. Create config files
echo "📝 Creating configuration files..."
cat > "Mira 8/Config.xcconfig.template" << EOF
// Copy this to Config.xcconfig and fill in your keys
USDA_API_KEY = YOUR_KEY_HERE
EOF

# 2. Update .gitignore
echo "🔒 Updating .gitignore..."
if ! grep -q "Config.xcconfig" .gitignore; then
    echo "Config.xcconfig" >> .gitignore
    echo "**/.DS_Store" >> .gitignore
fi

# 3. Clean build artifacts
echo "🧹 Cleaning build artifacts..."
rm -rf ~/Library/Developer/Xcode/DerivedData/Mira*

# 4. Check for common issues
echo "🔍 Scanning for issues..."
echo "Checking for print statements..."
grep -r "^[[:space:]]*print(" "Mira 8/" --include="*.swift" | wc -l

echo "Checking for TODOs..."
grep -r "TODO\|FIXME" "Mira 8/" --include="*.swift"

echo "✅ Prep script complete!"
echo "Next steps:"
echo "1. Move your USDA API key to Config.xcconfig"
echo "2. Update Constants.swift to read from build settings"
echo "3. Fix the fatalError in CameraPreviewView.swift"
echo "4. Lower deployment target in Xcode project settings"
