# 🤖 BuddyBook Agent Handbook

Welcome, Agent! This document provides the essential context and guidelines for contributing to **BuddyBook**, a Flutter-based book management ecosystem.

## 📖 Project Overview
BuddyBook is a personal library assistant that helps users organize their physical books, track lendings, and discover new reads using AI.

- **Primary Goal:** Seamless book organization and lending management.
- **Key Features:** Barcode scanning, folder-based organization, AI-powered book chat, and real-time cloud sync.

## 🛠 Tech Stack
- **Framework:** Flutter (SDK `>=3.0.0 <4.0.0`)
- **State Management:** `flutter_bloc` (primary) and `provider` (secondary/legacy).
- **Navigation:** `go_router` for declarative routing.
- **Backend:** Firebase (Auth, Realtime Database, Storage, Analytics, Crashlytics).
- **Data Handling:** `freezed` & `json_serializable` for immutable models.
- **AI Integration:** `google_generative_ai` (Gemini) and `flutter_ai_toolkit`.
- **Dependency Injection:** `get_it` (Service Locator).

## 🏗 Architecture
We follow **Clean Architecture** principles to maintain a decoupled and testable codebase:

- **`lib/core`**: Common utilities, constants, DI setup, and base error classes.
- **`lib/domain`**: The "Heart" of the app. Contains Entities and Repository interfaces.
- **`lib/data`**: Implementation of Repositories, Data Sources (Remote/Local), and DTOs (Models).
- **`lib/presentation`**: UI layer. Organized by `pages`, `widgets`, and `blocs`.
- **`lib/services`**: Infrastructure-specific services (e.g., Firebase wrappers).

## 📏 Coding Standards & Patterns
1. **Functional Error Handling:** Use `dartz` (`Either<Failure, Success>`) for domain and data layer methods instead of throwing exceptions.
2. **Immutability:** All data models should use `@freezed`.
3. **Naming Conventions:**
    - Blocs: `FeatureBloc`, `FeatureEvent`, `FeatureState`.
    - Repositories: `IFeatureRepository` (domain) and `FeatureRepositoryImpl` (data).
4. **Widget Structure:** Prefer composition. Keep widgets small and specialized.
5. **DI Usage:** Register new services in `lib/core/di/service_locator.dart`.

## 🧭 Agent Instructions
- **Before Editing:** Always check `lib/core/di/service_locator.dart` to understand how dependencies are wired.
- **Navigation Changes:** Routes are defined in `lib/presentation/navigation/app_router.dart`.
- **Firebase:** Respect the structures defined in `lib/core/constants/firebase_constants.dart`.
- **ML & AI:** Be mindful of the 16KB page alignment requirements in Android builds when adding native dependencies.

---
*Happy coding, Agent. Let's build the best library for book lovers!* 📚✨
