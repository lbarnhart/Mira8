# Mira 8 Developer Setup

## 1. Configure Secrets

1. Copy the build configuration template:
   ```bash
   cp App/Configuration/Config.xcconfig.template App/Configuration/Config.xcconfig
   ```
2. Edit `App/Configuration/Config.xcconfig` and provide your USDA FoodData Central API key.
3. Copy the runtime configuration template if you plan to use Instacart or Amazon features:
   ```bash
   cp "Mira 8/App/Configuration/Configuration.sample.plist" "Mira 8/App/Configuration/Configuration.plist"
   ```
4. Fill in the Instacart Connect client ID/secret and Amazon Associates tag inside the new plist. Leaving values blank disables those integrations gracefully.

## 2. Logging

- All runtime logging uses the lightweight `AppLog` wrapper around `os.Logger`.
- `AppLog.debug`/`AppLog.info` emit output only in DEBUG builds, while warnings and errors are always surfaced.
- Use the predefined categories (`.network`, `.scanner`, `.configuration`, `.persistence`, `.scoring`, `.general`) to keep Console output organized.

## 3. Build

- The project now targets **iOS 16.0** and later. Ensure your simulator/device meets this requirement.
- After configuring the files above, clean the build folder and run the app from Xcode.

