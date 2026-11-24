#!/bin/sh
# Build clang-p2996 (clang, lld, libc++, libc++abi, libunwind) for x86_64 Linux
# and pack it as OUT/clang-p2996-<version>-x86_64-linux-gnu.tar.xz.
#
# Usage: build-linux.sh [REF] [OUT]
# Env:   WORK (scratch dir, default ./work), JOBS, LINK_JOBS, CC, CXX
set -eu
here=$(cd "$(dirname "$0")" && pwd)
REF="${1:-p2996}"
OUT="${2:-$PWD/out}"
WORK="${WORK:-$PWD/work}"
JOBS="${JOBS:-$(nproc)}"
LINK_JOBS="${LINK_JOBS:-2}"
mkdir -p "$OUT" "$WORK"
OUT=$(cd "$OUT" && pwd)
WORK=$(cd "$WORK" && pwd)

SRC="$WORK/llvm-project"
"$here/fetch-source.sh" "$REF" "$SRC"
VERSION=$("$here/version.sh" "$SRC")
NAME="clang-p2996-$VERSION-x86_64-linux-gnu"
PREFIX="$WORK/install/$NAME"
BUILD="$WORK/build-linux"

cmake -G Ninja -S "$SRC/llvm" -B "$BUILD" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$PREFIX" \
    -DCMAKE_C_COMPILER="${CC:-clang-12}" \
    -DCMAKE_CXX_COMPILER="${CXX:-clang++-12}" \
    -DLLVM_USE_LINKER=lld \
    -DLLVM_ENABLE_PROJECTS="clang;lld" \
    -DLLVM_ENABLE_RUNTIMES="libcxx;libcxxabi;libunwind" \
    -DLLVM_TARGETS_TO_BUILD=X86 \
    -DLLVM_ENABLE_ASSERTIONS=OFF \
    -DLLVM_LINK_LLVM_DYLIB=ON \
    -DLLVM_INSTALL_TOOLCHAIN_ONLY=ON \
    -DLLVM_ENABLE_PER_TARGET_RUNTIME_DIR=ON \
    -DLLVM_INCLUDE_TESTS=OFF \
    -DLLVM_INCLUDE_BENCHMARKS=OFF \
    -DLLVM_INCLUDE_EXAMPLES=OFF \
    -DLLVM_INCLUDE_DOCS=OFF \
    -DCLANG_INCLUDE_TESTS=OFF \
    -DCLANG_INCLUDE_DOCS=OFF \
    -DCLANG_DEFAULT_CXX_STDLIB=libc++ \
    -DLIBCXX_INCLUDE_BENCHMARKS=OFF \
    -DLLVM_ENABLE_LIBXML2=OFF \
    -DLLVM_ENABLE_ZSTD=OFF \
    -DLLVM_PARALLEL_LINK_JOBS="$LINK_JOBS"

cmake --build "$BUILD" -j "$JOBS"
cmake --install "$BUILD" --strip
cmake --build "$BUILD" --target install-runtimes

# libc++ is a shared library next to the toolchain; embed an rpath to it so
# programs built with this clang++ run without LD_LIBRARY_PATH.
LIBCXX=$(find "$PREFIX/lib" -name 'libc++.so.1' | head -n 1)
[ -n "$LIBCXX" ] || { echo "libc++.so.1 not found under $PREFIX/lib" >&2; exit 1; }
LIBDIR_REL=$(dirname "${LIBCXX#"$PREFIX"/}")
printf '%s\n' "-Wl,-rpath,<CFGDIR>/../$LIBDIR_REL" > "$PREFIX/bin/clang++.cfg"
[ -f "$PREFIX/include/c++/v1/meta" ] || { echo "<meta> missing from the install" >&2; exit 1; }

cp "$SRC/llvm/LICENSE.TXT" "$PREFIX/"
printf 'bloomberg/clang-p2996 %s\n' "$(git -C "$SRC" rev-parse HEAD)" > "$PREFIX/VERSION.txt"

"$here/smoke-test-linux.sh" "$PREFIX"

XZ_OPT="-T0 -6" tar -C "$WORK/install" --owner=0 --group=0 --numeric-owner \
    -cJf "$OUT/$NAME.tar.xz" "$NAME"
ls -l "$OUT/$NAME.tar.xz"
