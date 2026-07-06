# ScoreDen

A clean, modern scorekeeping and session-tracking application built with Flutter. ScoreDen simplifies game nights by logging match dynamics, player counts, ruleset types, and detailed history loops under a unified custom design scheme.

## Design Language & Core Tokens

The application follows a custom, dark-mode-first aesthetic powered by centralized theme properties. If you are modifying layouts or introducing new views, stick to these predefined design boundaries:

- **Shapes**: Components use standard rounded tracks (BorderRadius.circular(12) for structural elements/cards and 16 for interactive data chips).
- **Stylized Card System**: Avoid raw Card widgets. Use the custom component wrapper `StylizedCard()`. It automatically applies an elegant left-side glowing drop shadow utilizing an offset vector. This projects a thematic accent ring around the left edge without heavy, dark-rimmed boundaries on the other three planes.
- **Component Rhythm**: Data indicators (like match counts, dates, and rule labels) are engineered using inline micro-chips matching dynamic colors:
    - `AppTheme.highestWins` & `AppTheme.highestWinsForeground` (Green accent rulesets)
    - `AppTheme.lowestWins` & `AppTheme.lowestWinsForeground` (Red/Yellow accent rulesets)

## Essential Development Commands

Here is a breakdown of the day-to-day terminal routines required to test, compile, and maintain the codebase.

### 1. Environment & Setup

Before kicking off a code sprint, ensure your workspace packages are synced and valid:
Bash

```dart
# Safely wipe out local build artifacts, cache configurations, and intermediate directories
flutter clean

# Retrieve all dependency packages declared inside your pubspec.yaml file
flutter pub get

# Inspect your system environment setup and verify connected hardware simulation states
flutter doctor
```

### 2. Execution & Live Reloading

Launch the runtime environment on your preferred emulator or local device asset:
Bash

```dart
# Launch the application target in standard debug execution mode
flutter run

# Compile specifically targeting web browsers with standard rendering controls
flutter run -d chrome
```

> Pro-Tip for Interactive Flow: When testing styling or UI changes inline inside the terminal workspace, press r to trigger a Hot Reload (injects updated structural logic in sub-seconds while persisting variable state) or capital R to trigger a complete Hot Restart.

### 3. Verification & Code Quality

Run these checking tools before pushing local branch changes up to your repository:
Bash

```dart
# Evaluate the entire codebase against standard Dart language rules and project formatting configurations
flutter analyze

# Execute your automated unit and widget test files across the test directory spectrum
flutter test
```

### 4. Build Generation & Packaging

When you are ready to compile optimized, standalone binaries for release testing:
Bash

```dart
# Generate an optimized, split-architecture Android App Bundle ready for Google Play Console submission
flutter build appbundle

# Compile an absolute standalone Android APK binary package
flutter build apk --release

# Assemble an optimized distribution build bundle targeting iOS devices (Requires a macOS workstation)
flutter build ipa
```