# Token Balance Branding Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rename the user-facing macOS app to “Token 余量” / “Token Balance” and ship the approved quota-segment icon in the application bundle.

**Architecture:** Preserve `com.tokenbar.macos`, the `TokenBar` executable, and existing Watcher storage identifiers for upgrade compatibility. Change only user-facing metadata, menu copy, documentation, output bundle/archive names, and add a generated `.icns` resource.

**Tech Stack:** Objective-C/AppKit, plist metadata, Bash, `sips`, `iconutil`.

## Global Constraints

- Chinese display name is `Token 余量`.
- English product name is `Token Balance`.
- Menu bar shorthand remains `Token`.
- Preserve bundle identifier `com.tokenbar.macos` and Watcher compatibility paths.
- Use the approved Scheme A icon without text or third-party branding.

---

### Task 1: Add a branding regression check

**Files:**
- Create: `scripts/test-branding.sh`

**Interfaces:**
- Consumes: built application bundle under `outputs/Token Balance.app` whose system display name is `Token 余量`.
- Produces: a nonzero exit when display metadata, icon packaging, archive naming, or legacy output cleanup is incorrect.

- [x] Write assertions for the visible product name, stable bundle ID and executable, `.icns` resource, renamed ZIP, and absence of legacy outputs.
- [x] Run `bash scripts/test-branding.sh` and confirm it fails because the renamed bundle does not yet exist.

### Task 2: Package the icon and rename visible surfaces

**Files:**
- Modify: `Resources/Info.plist`
- Modify: `Sources/TokenBarApp/TBAppDelegate.m`
- Modify: `Sources/TokenBarCore/TokenBarCore.m`
- Modify: `scripts/build-app.sh`
- Modify: `README.md`
- Generate: `Resources/TokenBalance.icns`
- Generate: `outputs/Token Balance.app`
- Generate: `outputs/Token-Balance-macOS.zip`

**Interfaces:**
- Consumes: `Resources/AppIconConcepts/token-balance-concept-a-v1.png`.
- Produces: a signed macOS application with `CFBundleDisplayName=Token 余量`, `CFBundleName=Token Balance`, and `CFBundleIconFile=TokenBalance`.

- [x] Generate the complete macOS iconset and compile it to `TokenBalance.icns`.
- [x] Update plist metadata and user-facing tooltip/client title while preserving compatibility identifiers.
- [x] Update the build script to package the icon and emit the renamed bundle/archive.
- [x] Update installation and product wording in the README.
- [x] Run unit tests, build the application, run branding checks, validate signing, and inspect packaged metadata.
