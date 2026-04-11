# Mira 8 Developer Setup

## 1. Configure Secrets

1. Copy the runtime configuration template:
   ```bash
   cp App/Configuration/Configuration.sample.plist App/Configuration/Configuration.plist
   ```
2. Edit `App/Configuration/Configuration.plist` and provide the keys you plan to use.
3. `USDAAPIKey` is required for food lookup coverage.
4. `ClaudeAPIKey` is optional. Leaving it blank disables photo scan and AI-assisted analysis.
5. `PrivacyPolicyURL`, `TermsOfServiceURL`, `HelpCenterURL`, and `SupportEmail` are optional in development, but you should populate them before App Store submission.

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
- Open [Mira.xcodeproj](/Users/laurenbarnhart/Mira8/Mira.xcodeproj) in Xcode and let it resolve package/indexing state.
- The project now targets **iOS 16.0** and later. Ensure your simulator/device meets this requirement.
- After configuring `Configuration.plist`, clean the build folder and run the `Mira 8` scheme from Xcode.
