#!/bin/bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
app="$project_dir/outputs/Token Balance.app"
plist="$app/Contents/Info.plist"

fail() { echo "FAIL: $1" >&2; exit 1; }
assert_equal() { [[ "$1" == "$2" ]] || fail "$3 (expected '$2', got '$1')"; }

[[ -d "$app" ]] || fail "renamed app bundle is missing"
[[ -f "$plist" ]] || fail "Info.plist is missing"
assert_equal "$(plutil -extract CFBundleDisplayName raw -o - "$plist")" "Token 余量" "display name"
assert_equal "$(plutil -extract CFBundleName raw -o - "$plist")" "Token Balance" "bundle name"
assert_equal "$(plutil -extract CFBundleIdentifier raw -o - "$plist")" "com.tokenbar.macos" "bundle identifier"
assert_equal "$(plutil -extract CFBundleExecutable raw -o - "$plist")" "TokenBar" "executable name"
assert_equal "$(plutil -extract CFBundleIconFile raw -o - "$plist")" "TokenBalance" "icon file"
assert_equal "$(plutil -extract CFBundleShortVersionString raw -o - "$plist")" "1.0.0" "release version"
[[ -f "$app/Contents/Resources/TokenBalance.icns" ]] || fail "packaged icon is missing"
[[ -x "$app/Contents/Resources/Token Balance Watcher" ]] || fail "renamed background watcher is missing"
[[ ! -e "$app/Contents/Resources/TokenBarWatcher" ]] || fail "legacy background watcher is still packaged"
[[ -f "$project_dir/outputs/Token-Balance-macOS.zip" ]] || fail "renamed archive is missing"
[[ ! -e "$project_dir/outputs/TokenBar.app" ]] || fail "legacy app output still exists"
[[ ! -e "$project_dir/outputs/Token 余量.app" ]] || fail "legacy localized app output still exists"
[[ ! -e "$project_dir/outputs/TokenBar-macOS.zip" ]] || fail "legacy archive output still exists"

echo "PASS Token Balance branding"
