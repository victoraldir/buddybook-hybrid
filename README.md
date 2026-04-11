# BuddyBook

[![CI](https://github.com/victoraldir/BuddyBook/actions/workflows/ci.yml/badge.svg)](https://github.com/victoraldir/BuddyBook/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A personal book management app for Android, built with Flutter. Organize your book collection into folders, search and add books via Google Books or barcode scanning, create custom books with photos, track lending, and add personal annotations — all synced in real time with Firebase.

Originally built as a native Java Android app with ~8,000 users, now fully migrated to Flutter with clean architecture.

<!-- Screenshots: add actual screenshots here after publishing -->
<!-- ![Screenshots](docs/screenshots.png) -->

## Features

- **Google Sign-In** — one-tap authentication
- **Folder organization** — default "My Books" folder plus unlimited custom folders
- **Book search** — Google Books API with Open Library ISBN fallback
- **Barcode scanning** — scan a book's ISBN to add it instantly
- **Custom books** — manually create books with camera/gallery photo upload to Firebase Storage
- **Book lending** — track who borrowed your books and when
- **Annotations** — full-screen notepad for personal notes on each book
- **Real-time sync** — Firebase Realtime Database with live listeners across all screens
- **Subscription system** — free tier (50 books) and yearly premium (unlimited), powered by Google Play Billing via `in_app_purchase`
- **Adaptive icons** — proper Android adaptive icons with teal background

## Architecture

Clean Architecture with BLoC pattern for state management:

```
lib/
├── main.dart
├── config/theme.dart                 # Teal/deep-orange Material theme
├── core/
│   ├── constants/                    # Firebase paths, API keys, subscription constants
│   ├── di/service_locator.dart       # GetIt dependency injection
│   ├── errors/                       # Exceptions & failures
│   ├── network/                      # Dio HTTP client
│   └── utils/                        # Date formatting, extensions
├── data/
│   ├── datasources/                  # Firebase RTDB, Google Books API, Open Library API
│   ├── models/                       # JSON-serializable models (book, user, folder, volume_info)
│   └── repositories/                 # Repository implementations
├── domain/
│   ├── entities/                     # Domain entities (Book, User, Folder, VolumeInfo)
│   └── repositories/                 # Abstract repository contracts
├── presentation/
│   ├── blocs/                        # BookBloc, FolderBloc, LendBloc, BookSearchBloc
│   ├── navigation/app_router.dart    # GoRouter configuration
│   ├── pages/                        # Auth, Home, Books, Folders, Lends, Settings
│   ├── providers/                    # AuthStateProvider
│   └── widgets/                      # Reusable widgets, subscription dialog
└── services/                         # SubscriptionService (IAP wrapper)
```

### Key Design Decisions

- **Nested Firebase structure**: `users/{uid}/folders/{folderId}/books/{bookId}` — matches the original Java app's database, preserving backward compatibility with ~8,000 existing users
- **BLoC with real-time streams**: All list screens use Firebase `.onValue` streams, not one-shot fetches
- **Factory-registered BLoCs**: Each page creates its own BLoC instance via GetIt factory, properly disposed on page exit
- **Subscription guard**: Book creation is checked against the user's tier before writing to Firebase

## Getting Started

### Prerequisites

- Flutter SDK 3.0+ (Dart 3.0+)
- Android SDK (API 21+, targetSdk 35)
- A Firebase project with Realtime Database and Authentication enabled

### Setup

```bash
# Clone and install
git clone https://github.com/victoraldir/BuddyBook.git
cd buddybook_flutter
flutter pub get

# Generate JSON serialization code
dart run build_runner build --delete-conflicting-outputs

# Run on connected device
flutter run
```

### Firebase Configuration

The app expects:
- `android/app/google-services.json` — Firebase Android config
- Firebase Authentication with Google Sign-In enabled
- Firebase Realtime Database at `https://buddybook-d08c8.firebaseio.com`
- Firebase Storage at `buddybook-d08c8.appspot.com`

## Subscription Tiers

| Tier | Book Limit | Price |
|------|-----------|-------|
| Free | 50 books | Free |
| Premium | Unlimited | ~1/year |

Product ID: `buddybook_premium_yearly` (configured via Google Play Console).

## Development

```bash
# Run tests
flutter test

# Analyze code
dart analyze

# Format code
dart format lib/

# Regenerate models after editing .dart model files
dart run build_runner build --delete-conflicting-outputs
```

## Tech Stack

| Category | Libraries |
|----------|-----------|
| Firebase | firebase_core, firebase_auth, firebase_database, firebase_storage, firebase_analytics, firebase_crashlytics |
| State | flutter_bloc, provider |
| Navigation | go_router |
| Networking | dio, retrofit |
| Models | json_serializable, freezed_annotation, equatable |
| Camera | mobile_scanner, image_picker, camera |
| IAP | in_app_purchase |
| DI | get_it |
| Storage | shared_preferences, hive_flutter |

## Original Project

This is a Flutter rewrite of the original Java/Android app: [BuddyBook (Java)](https://github.com/victoraldir/BuddyBook)

The migration preserves full backward compatibility with the existing Firebase database — no data migration required for existing users.

## License

MIT License - see [LICENSE](LICENSE) for details.
