#!/bin/sh
# Build a Windows-hosted clang-p2996 toolchain for x86_64-w64-mingw32 (UCRT)
# with llvm-mingw's scripts, cross-compiled from Linux, and pack it as
# OUT/clang-p2996-<version>-x86_64-w64-mingw32-ucrt.zip.
#
# Stage 1 builds a Linux-hosted llvm-mingw from the fork (clang + mingw-w64 +
# the fork's libc++); stage 2 uses it to cross-build the Windows-hosted tools.
#
# Usage: build-windows.sh [REF] [OUT]
# Env:   WORK (scratch dir, default ./work), LINK_JOBS, LLVM_MINGW_TAG
set -eu
here=$(cd "$(dirname "$0")" && pwd)
REF="${1:-p2996}"
OUT="${2:-$PWD/out}"
WORK="${WORK:-$PWD/work}"
# The fork branched from LLVM main on 2025-07-02; this llvm-mingw release
# (LLVM 21.1.0-rc1) has scripts matching that LLVM.
LLVM_MINGW_TAG="${LLVM_MINGW_TAG:-20250717}"
mkdir -p "$OUT" "$WORK"
OUT=$(cd "$OUT" && pwd)
WORK=$(cd "$WORK" && pwd)

LM="$WORK/llvm-mingw"
[ -d "$LM" ] || git clone -q --depth 1 --branch "$LLVM_MINGW_TAG" \
    https://github.com/mstorsjo/llvm-mingw.git "$LM"
# build-llvm.sh skips its own (hardcoded llvm/llvm-project) checkout when
# llvm-project/ already exists, so put the fork there.
"$here/fetch-source.sh" "$REF" "$LM/llvm-project"
VERSION=$("$here/version.sh" "$LM/llvm-project")
NAME="clang-p2996-$VERSION-x86_64-w64-mingw32-ucrt"
STAGE1="$WORK/stage1"
DEST="$WORK/install/$NAME"

export TOOLCHAIN_ARCHS=x86_64
export DEFAULT_CRT=ucrt
export LLVM_CMAKEFLAGS="-DLLVM_TARGETS_TO_BUILD=X86 -DLLVM_ENABLE_LIBXML2=OFF -DLLVM_ENABLE_ZSTD=OFF -DLLVM_INCLUDE_TESTS=OFF -DLLVM_INCLUDE_BENCHMARKS=OFF -DLLVM_INCLUDE_EXAMPLES=OFF -DCLANG_INCLUDE_TESTS=OFF -DLLVM_PARALLEL_LINK_JOBS=${LINK_JOBS:-2}"
COMMON="--disable-lldb --disable-lldb-mi --disable-clang-tools-extra"

cd "$LM"
[ -x "$STAGE1/bin/clang" ] && [ -n "${REUSE_STAGE1:-}" ] || ./build-all.sh "$STAGE1" $COMMON
./build-cross-tools.sh "$STAGE1" "$DEST" x86_64 $COMMON --disable-make

[ -f "$DEST/include/c++/v1/meta" ] || { echo "<meta> missing from the install" >&2; exit 1; }
printf 'bloomberg/clang-p2996 %s\r\nllvm-mingw %s\r\n' \
    "$(git -C "$LM/llvm-project" rev-parse HEAD)" "$LLVM_MINGW_TAG" > "$DEST/VERSION.txt"

(cd "$WORK/install" && zip -9rq "$OUT/$NAME.zip" "$NAME")
ls -l "$OUT/$NAME.zip"
