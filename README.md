# Momentum

Momentum is a finite, swipe-sized learning feed for software engineers. It turns
a quick phone break into a few practical DSA, functional programming, and code
craft wins—without an account, an API, or an endless feed.

## What is included

- Ten curated micro-lessons, quizzes, code patterns, and bug hunts
- Topic filters for DSA, functional programming, and code craft
- XP, daily progress, streaks, bookmarks, and answer explanations
- A clear end-of-session screen instead of infinite scrolling
- On-device persistence with `shared_preferences`
- Adaptive Material 3 UI for iOS and Android

## Run locally

Install the latest stable [Flutter SDK](https://docs.flutter.dev/get-started/install),
then check your platform toolchain:

```sh
flutter doctor
flutter pub get
```

Run on an attached Android device or emulator:

```sh
flutter run -d android
```

Run on an iOS simulator (macOS with Xcode required):

```sh
open -a Simulator
flutter run -d ios
```

For a quick browser preview:

```sh
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 43123
```

better way:
```sh
flutter run -d chrome
```

## Quality checks

```sh
flutter analyze
flutter test
flutter build web
```

The controller and scoring rules are covered by unit tests; onboarding,
learning, and bookmarking are covered by widget tests.

## Project structure

```text
lib/
  core/                       # Theme and shared widgets
  features/feed/
    application/              # Progress and interaction state
    data/                     # Curated content and persistence
    domain/                   # Learning and progress models
    presentation/             # Screens and feed cards
```
