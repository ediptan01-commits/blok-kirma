#!/usr/bin/env bash
set -euo pipefail
mkdir -p assets/audio
SOURCE_COMMIT=4a3de089a6be0a8000c130123ac7108736d1d1a9
BASE="https://raw.githubusercontent.com/yegors/hard-lines/${SOURCE_COMMIT}/public/audio"
for index in 0 1 2; do
  file="assets/audio/mp5-report-${index}.wav"
  curl --fail --location --silent --show-error --retry 4 --retry-delay 2 \
    --output "${file}" "${BASE}/mp5-report-${index}.wav"
  test "$(wc -c < "${file}")" -gt 20000
  head -c 4 "${file}" | grep -q "RIFF"
  echo "CC0 gerçek silah kaydı indirildi: ${file}"
done
