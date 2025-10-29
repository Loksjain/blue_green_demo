#!/usr/bin/env bash
set -euo pipefail

URL="${1:-http://localhost:3000/}"
EXPECTED_COLOR="${2:-}"

response="$(curl --fail --silent --show-error "${URL}")"

color="$(printf '%s' "${response}" | python -c 'import json,sys; payload=json.load(sys.stdin); print(payload.get("color",""))')"

if [[ -z "${color}" ]]; then
  echo "Smoke test failed: could not extract color from response at ${URL}" >&2
  echo "${response}" >&2
  exit 1
fi

if [[ -n "${EXPECTED_COLOR}" && "${color}" != "${EXPECTED_COLOR}" ]]; then
  echo "Smoke test failed: expected color ${EXPECTED_COLOR}, got ${color}" >&2
  exit 2
fi

echo "Smoke test passed for color ${color} at ${URL}"
