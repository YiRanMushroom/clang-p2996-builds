#!/bin/sh
# Print <commit date, UTC, YYYYMMDD>-<10-char sha> of the checkout in $1.
# The workflow computes the same string to name releases.
set -eu
TZ=UTC git -C "$1" log -1 --date=format-local:%Y%m%d --format='%cd-%H' | cut -c1-19
