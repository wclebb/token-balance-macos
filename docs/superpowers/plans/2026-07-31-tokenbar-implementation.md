# TokenBar Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build and package a native macOS menu bar app that displays ChatGPT Weekly percentage, remaining uses, natural reset countdown, and expiring extra Reset alerts.

**Architecture:** A Swift Package executable hosts a SwiftUI `MenuBarExtra`. Platform-neutral usage models and formatting are separated from a pluggable `UsageProvider`; the ChatGPT provider imports locally captured JSON and caches the last successful snapshot. A notification coordinator evaluates thresholds without exposing credentials.

**Tech Stack:** Objective-C, AppKit, Foundation, UserNotifications, clang, POSIX shell packaging. Swift was rejected after the installed compiler and SDK reported incompatible build versions.

## Global Constraints

- Target arm64 macOS 14 or newer.
- Do not upload session, credential, or usage data.
- Never invent an exact remaining-use count when the source omits it.
- Keep ChatGPT acquisition behind `UsageProvider` for future platforms.
- Build without third-party dependencies or a full Xcode installation.

---

### Task 1: Domain model, formatter, and package scaffold

**Files:**
- Create: `Sources/TokenBarCore/TokenBarCore.h`
- Create: `Sources/TokenBarCore/TokenBarCore.m`
- Test: `Tests/TokenBarCoreTests.m`

**Interfaces:**
- Produces: `UsageSnapshot`, `WeeklyAllowance`, `ExtraReset`, `MenuBarFormatter.label(snapshot:now:alertThreshold:) -> MenuBarLabel`.

- [ ] Write tests for `72% · W37 · 2d`, expiring `72% · W37 · R×1 8h`, missing values, and stale snapshots.
- [ ] Run `swift test` and confirm the missing-model failure.
- [ ] Implement Codable/Sendable domain types and deterministic formatting.
- [ ] Run `swift test` and confirm all formatter tests pass.

### Task 2: Provider parsing and local cache

**Files:**
- Modify: `Sources/TokenBarCore/TokenBarCore.h`
- Modify: `Sources/TokenBarCore/TokenBarCore.m`
- Test: `Tests/TokenBarCoreTests.m`

**Interfaces:**
- Produces: `UsageProvider.fetchUsage() async throws -> UsageSnapshot`, `ChatGPTSnapshotParser.parse(data:)`, and `SnapshotCache.load/save`.

- [ ] Write parser tests for canonical JSON, alternative snake_case keys, omitted exact count, malformed dates, and extra unknown fields.
- [ ] Run the focused parser tests and confirm failure.
- [ ] Implement the provider protocol, tolerant parser, file-backed provider, and atomic JSON cache.
- [ ] Run all tests and confirm parser/cache behavior passes.

### Task 3: Store, settings, and notification decisions

**Files:**
- Modify: `Sources/TokenBarCore/TokenBarCore.h`
- Modify: `Sources/TokenBarCore/TokenBarCore.m`
- Create: `Sources/TokenBarApp/TBUsageStore.h`
- Create: `Sources/TokenBarApp/TBUsageStore.m`
- Test: `Tests/TokenBarCoreTests.m`

**Interfaces:**
- Produces: `AlertEvaluator.events(snapshot:now:settings:) -> [UsageAlert]`; `UsageStore` publishes snapshot, error, refresh state, and refresh action.

- [ ] Write threshold and notification-deduplication tests.
- [ ] Run tests and confirm failure.
- [ ] Implement settings defaults, alert evaluation, refresh scheduling, cache fallback, and error states.
- [ ] Run all tests.

### Task 4: Native menu bar UI

**Files:**
- Create: `Sources/TokenBarApp/main.m`
- Create: `Sources/TokenBarApp/TBAppDelegate.h`
- Create: `Sources/TokenBarApp/TBAppDelegate.m`

**Interfaces:**
- Consumes: `UsageStore`, `MenuBarFormatter`, `TokenBarSettings`, `UsageAlert`.
- Produces: a menu bar label, detail panel, settings window, JSON import action, refresh action, and notifications.

- [ ] Implement `MenuBarExtra` with the approved label hierarchy and accessibility text.
- [ ] Implement the detail panel for Weekly/reset/sync/error states.
- [ ] Implement settings and secure local file selection for imported snapshots.
- [ ] Implement notification authorization and deduplicated delivery.
- [ ] Run `scripts/build-app.sh` and resolve compiler errors.

### Task 5: Packaging, fixtures, and delivery verification

**Files:**
- Create: `Resources/sample-chatgpt-usage.json`
- Create: `scripts/build-app.sh`
- Create: `README.md`
- Generate: `outputs/TokenBar.app`
- Generate: `outputs/TokenBar-macOS.zip`

**Interfaces:**
- Produces: a Finder-launchable `.app`, zipped distribution, and documented JSON acquisition/import contract.

- [ ] Add a sample snapshot matching `72% · W37 · 2d` and an expiring Reset.
- [ ] Add a packaging script that creates `Info.plist`, copies the release binary, and ad-hoc signs when `codesign` is available.
- [ ] Document build, launch, login-data limitations, privacy, and Provider extension points.
- [ ] Run the Objective-C test binary and application build.
- [ ] Run the packaging script, inspect the bundle and signature, then zip it.
- [ ] Perform a smoke launch with the sample data and confirm the process stays alive without crashing.
