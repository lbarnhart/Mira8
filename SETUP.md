# Mira 8 Developer Setup

## 1. Configure Runtime Values

1. Copy the runtime configuration template:
   ```bash
   cp App/Configuration/Configuration.sample.plist Mira/Resources/Configuration.plist
   ```
2. Edit `Mira/Resources/Configuration.plist` and provide the values you plan to use. Files in
   `Mira/Resources` are part of the app target; the generated file is ignored by Git.
3. `USDAAPIKey` is optional because Open Food Facts and the local essentials catalog are the primary lookup paths. A key placed in an iOS bundle can be extracted; for production USDA capacity, proxy requests through a controlled backend instead of treating a bundled key as secret.
4. `ClaudeAPIKey` is accepted only in DEBUG builds for local development. Release builds use
   on-device product-label recognition and never embed this provider credential.
5. `PrivacyPolicyURL`, `TermsOfServiceURL`, `HelpCenterURL`, and `SupportEmail` are optional in
   development, but must be populated before App Store submission.

## 2. Logging

- All runtime logging uses the lightweight `AppLog` wrapper around `os.Logger`.
- `AppLog.debug`/`AppLog.info` emit output only in DEBUG builds, while warnings and errors are always surfaced.
- Use the predefined categories (`.network`, `.scanner`, `.configuration`, `.persistence`, `.scoring`, `.general`) to keep Console output organized.

## 3. Build

- Install the full Xcode app. `xcodebuild` will not work with Command Line Tools alone.
- After installing Xcode, point developer tools at it:
  ```bash
  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
  ```
- Open `Mira.xcodeproj` in Xcode and let it resolve package/indexing state.
- The project now targets **iOS 16.0** and later. Ensure your simulator/device meets this requirement.
- After configuring `Configuration.plist`, clean the build folder and run the `Mira 8` scheme from Xcode.
