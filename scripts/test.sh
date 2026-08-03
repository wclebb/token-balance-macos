#!/bin/bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
module_cache="$project_dir/work/clang-module-cache"
test_dir="$project_dir/work/test-bin"

mkdir -p "$module_cache" "$test_dir"
CLANG_MODULE_CACHE_PATH="$module_cache" clang \
  -fobjc-arc \
  -Wall -Wextra \
  -framework Foundation \
  -I "$project_dir/Sources/TokenBarCore" \
  "$project_dir/Tests/TokenBarCoreTests.m" \
  "$project_dir/Sources/TokenBarCore/TokenBarCore.m" \
  -o "$test_dir/TokenBarCoreTests"

"$test_dir/TokenBarCoreTests"
