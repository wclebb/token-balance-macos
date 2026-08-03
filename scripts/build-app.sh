#!/bin/bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
output_dir="$project_dir/outputs"
app_dir="$output_dir/Token Balance.app"
archive_path="$output_dir/Token-Balance-macOS.zip"
legacy_app="$output_dir/TokenBar.app"
legacy_localized_app="$output_dir/Token 余量.app"
legacy_archive="$output_dir/TokenBar-macOS.zip"
stage_dir="$(mktemp -d /private/tmp/tokenbar-build.XXXXXX)"
trap 'rm -rf "$stage_dir"' EXIT
staged_app="$stage_dir/Token Balance.app"
contents_dir="$staged_app/Contents"
macos_dir="$contents_dir/MacOS"
resources_dir="$contents_dir/Resources"
module_cache="$project_dir/work/clang-module-cache"

if [[ "$app_dir" != "$output_dir/Token Balance.app" ]]; then
  echo "Refusing to clean unexpected app path: $app_dir" >&2
  exit 1
fi
mkdir -p "$macos_dir" "$resources_dir" "$module_cache"
cp "$project_dir/Resources/Info.plist" "$contents_dir/Info.plist"
cp "$project_dir/Resources/TokenBalance.icns" "$resources_dir/TokenBalance.icns"

CLANG_MODULE_CACHE_PATH="$module_cache" clang \
  -fobjc-arc \
  -O2 \
  -mmacosx-version-min=14.0 \
  -Wall -Wextra \
  -I "$project_dir/Sources/TokenBarCore" \
  "$project_dir/Sources/TokenBarCore/TokenBarCore.m" \
  "$project_dir/Sources/TokenBarWatcher/main.m" \
  -framework Cocoa \
  -o "$resources_dir/Token Balance Watcher"

CLANG_MODULE_CACHE_PATH="$module_cache" clang \
  -fobjc-arc \
  -O2 \
  -mmacosx-version-min=14.0 \
  -Wall -Wextra \
  -I "$project_dir/Sources/TokenBarCore" \
  -I "$project_dir/Sources/TokenBarApp" \
  "$project_dir/Sources/TokenBarCore/TokenBarCore.m" \
  "$project_dir/Sources/TokenBarApp/TBUsageStore.m" \
  "$project_dir/Sources/TokenBarApp/TBWatcherInstaller.m" \
  "$project_dir/Sources/TokenBarApp/TBAppDelegate.m" \
  "$project_dir/Sources/TokenBarApp/main.m" \
  -framework Cocoa \
  -framework UserNotifications \
  -o "$macos_dir/TokenBar"

chmod +x "$macos_dir/TokenBar"
if command -v codesign >/dev/null 2>&1; then
  xattr -cr "$staged_app"
  codesign --force --deep --sign - "$staged_app"
fi

rm -f "$archive_path"
COPYFILE_DISABLE=1 /usr/bin/ditto -c -k --norsrc --noextattr --keepParent "$staged_app" "$archive_path"

# Keep an unpacked convenience copy, but sign and package from the clean temp
# location so file-provider metadata in Documents cannot contaminate releases.
rm -rf "$app_dir"
COPYFILE_DISABLE=1 cp -R "$staged_app" "$app_dir"

# Remove generated artifacts carrying the previous public product name.
rm -rf "$legacy_app"
rm -rf "$legacy_localized_app"
rm -f "$legacy_archive"

echo "$app_dir"
