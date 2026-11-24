#!/bin/sh
# Local build in the same Docker image CI uses.
# Usage: ./build.sh linux|windows [REF]     (output in ./out, scratch in ./work)
set -eu
T="${1:?usage: ./build.sh linux|windows [REF]}"
REF="${2:-p2996}"
cd "$(dirname "$0")"
docker build -t "clang-p2996-$T" -f "docker/$T.Dockerfile" docker
docker run --rm -v "$PWD:/work" -w /work -e JOBS -e LINK_JOBS -e REUSE_STAGE1 \
    "clang-p2996-$T" "scripts/build-$T.sh" "$REF" /work/out
