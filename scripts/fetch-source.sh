#!/bin/sh
# Shallow-fetch bloomberg/clang-p2996 at REF (branch, tag or commit) into DEST.
# Usage: fetch-source.sh REF DEST
set -eu
REF="$1"
DEST="$2"
REPO="${P2996_REPO:-https://github.com/bloomberg/clang-p2996.git}"

if [ ! -d "$DEST/.git" ]; then
    git init -q "$DEST"
    git -C "$DEST" remote add origin "$REPO"
fi
git -C "$DEST" fetch --depth 1 origin "$REF"
git -C "$DEST" checkout -q --force FETCH_HEAD
git -C "$DEST" log -1 --format='source: %H %cd %s'
