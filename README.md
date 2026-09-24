# Momentum

Momentum is a finite, swipe-sized learning feed for software engineers. It
delivers a daily draw of at most 50 DSA, functional programming, and code craft
cards, then provides a clear stopping point.

## Content delivery

The app ships with a 50-card fallback catalog under `assets/catalog/`, so a
fresh install works without a network. In production it can read the same JSON
schema from a public GitHub repository:

```text
manifest.json
batches/
  0001.json  # exactly 10 cards
  0002.json
```

Set the catalog root at build or run time:

```bash
flutter run \
  --dart-define=CONTENT_BASE_URL=https://raw.githubusercontent.com/OWNER/momentum-catalog/main/
```

The public catalog contains no secret. A separate private publisher scaffold
is under [`content-engine/`](content-engine/); its weekly GitHub Action validates
curated input and commits up to 350 new cards into the public catalog.

## Daily behavior

- New days draw unseen cards from the local SQLite catalog, capped at 50.
- The draw and each quiz's shuffled option order are persisted for that date.
- Remote content is downloaded in batches of 10.
- When a user approaches the end of the currently loaded pack, the next
  unfetched batch is cached and appended, up to the daily cap.
- If the network is unavailable, cached SQLite cards remain usable.
- Lifetime XP, streak, card history, answers, and bookmarks are stored locally.
- There is no account or cloud progress sync yet.

## Local storage

SQLite tables separate responsibilities:

- `cards` and `batches`: cached catalog
- `daily_pack`: ordered card IDs, option ordering, and today's completion
- `card_history`: lifetime completion/correctness
- `progress` and `saved_cards`: XP, streak, onboarding, and bookmarks

Yesterday's completion never makes today's feed permanently complete. A new
`daily_pack` is created for each local calendar date.

## Run locally

Install the latest stable [Flutter SDK](https://docs.flutter.dev/get-started/install):

```bash
flutter doctor
flutter pub get
```

Android:

```bash
flutter run -d android
```

iOS (macOS with Xcode):

```bash
flutter run -d ios
```

Browser preview:

```bash
dart run sqflite_common_ffi_web:setup --force
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 43123
```

## Quality checks

```bash
flutter analyze
flutter test
flutter build web
```

The tests cover SQLite persistence, finite daily draws, a new calendar day,
option-order persistence, offline fallback, near-end batch prefetch, scoring,
onboarding, and bookmarks.
