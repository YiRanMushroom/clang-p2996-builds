# clang-p2996-builds

Prebuilt toolchains of [bloomberg/clang-p2996](https://github.com/bloomberg/clang-p2996), the experimental Clang fork that implements C++26 reflection (P2996), for:

| Package | Runs on | Produces |
|---|---|---|
| `clang-p2996-<date>-<sha>-x86_64-linux-gnu.tar.xz` | x86_64 Linux, glibc 2.31+ | x86_64 Linux programs, libc++ by default |
| `clang-p2996-<date>-<sha>-x86_64-w64-mingw32-ucrt.zip` | x86_64 Windows | x86_64 Windows programs (mingw-w64, UCRT, libc++) |

Both ship the fork's libc++, which is where `<meta>` lives. Download one from [Releases](../../releases), unpack it, and compile with:

```sh
clang++ -std=c++26 -freflection main.cpp          # P2996
clang++ -std=c++26 -freflection-latest main.cpp   # plus the fork's other experimental features
```

On Windows, add both `bin` and `x86_64-w64-mingw32\bin` (libc++ DLLs) to `PATH`, or link with `-static`.

## How it is built

- **Linux**: a plain LLVM build (clang, lld, libc++/libc++abi/libunwind via `LLVM_ENABLE_RUNTIMES`) in an Ubuntu 20.04 container. `bin/clang++.cfg` adds an rpath to the bundled libc++.
- **Windows**: [llvm-mingw](https://github.com/mstorsjo/llvm-mingw)'s scripts (tag `20250717`, matching the fork's LLVM base) build a Linux-hosted llvm-mingw from the fork, then cross-compile the Windows-hosted toolchain with it.

Everything runs in Docker, so CI and local builds are the same:

```sh
./build.sh linux   [REF]   # REF: branch, tag or commit of bloomberg/clang-p2996 (default p2996)
./build.sh windows [REF]
```

Output goes to `out/`, scratch to `work/`. `JOBS` and `LINK_JOBS` (default 2) limit parallelism.

## CI

`.github/workflows/build.yml` runs on demand (Actions → build → Run workflow: pick targets, ref, and whether to publish) and every Monday, when it builds only if upstream `p2996` has a commit that has no release yet. Releases are tagged `p2996-<commit date>-<sha>`.
