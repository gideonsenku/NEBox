# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

NEBox is a native iOS client for BoxJS — a management tool for JavaScript automation scripts across proxy tools (Loon, Surge, Shadowrocket, Quantumult X). Built with SwiftUI + MVVM + Combine.

## Build & Run

```bash
# Open in Xcode (SPM dependencies resolve automatically)
open NEBox.xcodeproj

# Build from command line
xcodebuild -project NEBox.xcodeproj -scheme NEBox -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' build

# No test target exists yet
```

- **Xcode 15.4+**, **iOS 16.0+**, **Swift 5.0**
- Dependencies managed via Xcode SPM integration (no Package.swift or Podfile)

## Architecture

**MVVM + Combine** with a single shared ViewModel:

```
BoxJSAPI (Moya TargetType) → NetworkProvider (async request + envelope validation) → BoxJsViewModel (@Published state) → Views (@EnvironmentObject)
```

### Key layers:

- **Models/BoxDataModel.swift** — All data models (BoxDataResp, AppModel, AppSubCache, Session, Setting, etc.). This is the foundation — read it first.
- **Services/BoxJSAPI.swift** — Moya `TargetType` enum defining all 20 API endpoints with paths, methods, and parameter encoding.
- **Services/NetworkProvider.swift** — Generic `request<T>()` with `mapBoxJS<T>()` envelope validation (checks HTTP status + `code` field in JSON response).
- **Services/ApiRequest.swift** — High-level API helpers that compose ViewModel calls.
- **ViewModels/BoxJsViewModel.swift** — Single shared ViewModel holding all app state via `@Published` properties. Injected as `@EnvironmentObject`.
- **Managers/ApiManager.swift** — Singleton managing the BoxJS API base URL, persisted to UserDefaults.
- **Managers/ToastManager.swift** — Singleton for toast notifications.

### View hierarchy:

`ContentView` (welcome setup + TabView) routes to:
- `HomeView` — Favorite apps grid using UICollectionView wrapper, edit mode with jiggle animation
- `SubcribeView` — Subscription card management with drag-to-reorder
- `ProfileView` — User profile, global backup/restore
- `AppDetailView` — App settings forms (radio/checkbox/text), session management, data viewer, script execution

### BoxJS API contract:

All responses use envelope format: `{ "code": 0, "message": "...", ...payload }`. The `mapBoxJS<T>()` method validates `code` before decoding.

## Code Patterns

- **Async/await** throughout the networking layer (no callbacks)
- **UICollectionView wrappers** (`CollectionViewWrapper`, `SubCollectionViewWrapper`) for high-performance grid layouts bridged into SwiftUI
- **Fire-and-forget vs explicit errors**: `updateData()` is fire-and-forget; `updateDataAsync()` returns `Result<Void, UpdateError>`
- **Proxy tool detection**: Reads `syscfgs.env` from BoxDataResp to identify the active proxy tool (Loon/Surge/etc.)
- **NSAllowsArbitraryLoads** enabled in Info.plist (required — BoxJS runs on local HTTP)

## Dependencies (SPM)

| Package | Purpose |
|---------|---------|
| Moya / Alamofire | Network abstraction + HTTP |
| AnyCodable | Dynamic JSON type support |
| SDWebImageSwiftUI | Image loading & caching |
