# Token Balance

<p align="center">
  <a href="README.md">简体中文</a> · <strong>English</strong>
</p>

<p align="center">
  <img src="Resources/AppIconConcepts/token-balance-concept-a-v1-transparent.png" width="160" alt="Token Balance icon">
</p>

<p align="center">
  A local-first macOS menu bar utility for monitoring ChatGPT subscription usage.
</p>

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-black?logo=apple)
![Release](https://img.shields.io/badge/release-v1.0.0-blue)
![License](https://img.shields.io/badge/license-Apache--2.0-green)

## Features

- Displays your remaining Weekly allowance and the countdown to its natural reset.
- Shows the number of additional Resets available and warns you before they expire.
- Refreshes automatically every 60 seconds, with an option to refresh immediately.
- Uses a native hierarchical macOS menu and follows the system menu bar text color.
- Reuses the signed-in state of the local ChatGPT/Codex desktop app without requiring you to select files or sign in again.
- Starts and exits alongside ChatGPT through a lightweight background watcher.
- Uses a unified Provider model, leaving room for additional AI platforms in the future.

The normal menu bar format is:

```text
65% · R×2 · 6d
```

| Field | Meaning |
| --- | --- |
| `65%` | Remaining Weekly allowance |
| `R×2` | Two additional Resets are currently available |
| `6d` | Six days until the natural Weekly reset |

When an additional Reset is close to expiring, the final field temporarily changes to its nearest expiry countdown. If the upstream source does not provide an exact number of Weekly uses, the app displays `W—` rather than fabricating a count from the percentage.

## System Requirements

- An Apple silicon Mac (the current Release is built for arm64)
- macOS 14 Sonoma or later
- The ChatGPT/Codex desktop app installed and signed in

## Installation

1. Download `Token-Balance-macOS.zip` from [Releases](https://github.com/chakcodes/token-balance-macos/releases/latest).
2. Extract it and move `Token Balance.app` into Applications. The system display name is “Token 余量.”
3. The current Release uses an ad-hoc signature and is not notarized with an Apple Developer ID. If Gatekeeper blocks the first launch, right-click the app in Finder and select **Open**.

On first launch, Token Balance installs a user-level background component named `Token Balance Watcher`. Token Balance will then start when ChatGPT starts and exit when ChatGPT exits. If you quit Token Balance manually, the watcher will not reopen it during the current ChatGPT session.

Background component locations:

```text
~/Library/Application Support/Token Balance/Token Balance Watcher
~/Library/LaunchAgents/com.tokenbalance.watcher.plist
```

When upgrading from an early TokenBar build, the app automatically disables and removes the legacy watcher and LaunchAgent.

## Data and Privacy

Token Balance calls the local `app-server` included with the ChatGPT/Codex desktop app and reads the usage windows available for the current account:

- Weekly usage percentage and natural reset time;
- Available additional Reset count and expiry time;
- Current subscription plan and usage windows.

The app does not read, copy, upload, or store ChatGPT login tokens, and it does not operate its own cloud service. Notifications and preferences remain on your Mac.

> This project depends on a local app-server protocol that is not guaranteed to remain stable. Updates to the ChatGPT/Codex desktop app may require corresponding compatibility changes.

## Building from Source

A full Xcode installation is not required. Install Apple Command Line Tools, then run:

```bash
bash scripts/test.sh
bash scripts/build-app.sh
bash scripts/test-branding.sh
```

Generated artifacts:

```text
outputs/Token Balance.app
outputs/Token-Balance-macOS.zip
```

## Project Structure

```text
Sources/TokenBarCore/       Usage models, formatting, alerts, and Provider
Sources/TokenBarApp/        AppKit menu bar app and watcher installer
Sources/TokenBarWatcher/    ChatGPT lifecycle background watcher
Resources/                  Info.plist and App Icon
Tests/                      Core behavior tests
scripts/                    Build and verification scripts
```

Some internal class names, executable names, and the Bundle ID retain the `TokenBar` identifier for compatibility with early versions. They are not the current user-facing product name.

## Uninstallation

Quit Token Balance, delete the app, and run:

```bash
launchctl bootout "gui/$(id -u)" "$HOME/Library/LaunchAgents/com.tokenbalance.watcher.plist" 2>/dev/null || true
rm -f "$HOME/Library/LaunchAgents/com.tokenbalance.watcher.plist"
rm -rf "$HOME/Library/Application Support/Token Balance"
```

## Development Approach: AI-Assisted / Vibe Coding

This repository was designed and implemented with an AI-assisted Vibe Coding workflow. This disclosure describes the development process; it is not a substitute for engineering quality assurance. Executable behavior remains grounded in the source code, automated tests, and Release verification results. Review, modification, and redistribution are welcome.

## Contributing and Security

Please read [CONTRIBUTING.md](CONTRIBUTING.md) before submitting changes. Report security issues privately according to [SECURITY.md](SECURITY.md), and never include login tokens or personal data in a public Issue.

## License

This project is open source under the [Apache License 2.0](LICENSE). You may use, modify, and redistribute it, including for commercial purposes, subject to the copyright, license-copy, modification-notice, and patent provisions of the license.

## Trademark Notice

ChatGPT, OpenAI, Codex, and Apple are trademarks of their respective owners. This is an independent open-source project and is not affiliated with, sponsored by, or endorsed by OpenAI or Apple.
