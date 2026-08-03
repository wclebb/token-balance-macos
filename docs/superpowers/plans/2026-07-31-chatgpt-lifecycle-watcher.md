# ChatGPT Lifecycle Watcher Implementation Plan

**Goal:** Bundle and install a user-level watcher that launches and terminates TokenBar with ChatGPT.

**Architecture:** A tested lifecycle policy drives a tiny AppKit helper. TokenBar installs the helper and LaunchAgent on startup; the helper observes `NSWorkspace` application notifications.

1. Add failing lifecycle-policy tests, implement the state machine, and run the suite.
2. Add the Watcher executable and wire it to `NSWorkspace` notifications.
3. Add a TokenBar installer that copies the helper and loads a user LaunchAgent.
4. Package both binaries, run tests, verify signatures, install, and exercise the lifecycle.
