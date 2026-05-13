#!/usr/bin/env bash
# Regenerate pages/public-key.pem from the embedded constant in
# internal/license/keys.go. Run this from the control-plane repo with
# proxy/ checked out alongside it (or with PROXY_DIR pointing at the
# proxy worktree).
#
# The output must be byte-identical to `excalibur-ctl license keys export`
# so customers who diff the two are reassured.
set -euo pipefail
PROXY_DIR="${PROXY_DIR:-../proxy}"
OUT="${1:-pages/public-key.pem}"

if [[ ! -d "$PROXY_DIR" ]]; then
  echo "PROXY_DIR=$PROXY_DIR does not exist" >&2
  exit 1
fi

(cd "$PROXY_DIR" && go run ./cmd/excalibur-ctl license keys export) > "$OUT"
echo "[refresh-public-key] wrote $OUT ($(wc -c <"$OUT") bytes)"
