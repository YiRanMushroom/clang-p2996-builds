#!/bin/sh
# Compile and run tests/reflection-smoke.cpp with a Linux toolchain.
# Usage: smoke-test-linux.sh <toolchain dir | .tar.xz>
set -eu
here=$(cd "$(dirname "$0")" && pwd)
T="$1"
tmp=$(mktemp -d)
case "$T" in
*.tar.xz)
    tar -C "$tmp" -xJf "$T"
    T=$(find "$tmp" -mindepth 1 -maxdepth 1 -type d | head -n 1)
    ;;
esac
"$T/bin/clang++" --version
"$T/bin/clang++" -std=c++26 -freflection -fexpansion-statements \
    "$here/../tests/reflection-smoke.cpp" -o "$tmp/smoke"
"$tmp/smoke"
"$T/bin/clang++" -std=c++26 -freflection-latest \
    "$here/../tests/reflection-smoke.cpp" -o "$tmp/smoke-latest"
"$tmp/smoke-latest"
echo "smoke test passed"
