#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DESTINATION="${1:-$ROOT_DIR/macos/vendor/XiaoyuanAnQuanTong-macos-arm64}"
URL="https://github.com/hangone/study-xiaoyuananquantong/releases/download/v1.0.0/XiaoyuanAnQuanTong-macos-arm64"
EXPECTED="4556bc947caa2ea387ffb18a3649014035d5ed90ad6a3ef622ff896ac8d56d24"

mkdir -p "$(dirname "$DESTINATION")"
curl --fail --location --retry 3 --output "$DESTINATION" "$URL"
ACTUAL="$(shasum -a 256 "$DESTINATION" | awk '{print $1}')"
if [[ "$ACTUAL" != "$EXPECTED" ]]; then
  echo "上游 macOS 核心校验失败：期望 $EXPECTED，实际 $ACTUAL" >&2
  exit 1
fi
chmod 755 "$DESTINATION"
echo "上游 macOS 核心校验通过：$ACTUAL"
