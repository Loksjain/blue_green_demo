#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${1:-blue-green-demo}"

color="$(kubectl get service web --namespace "${NAMESPACE}" -o jsonpath='{.spec.selector.color}')"

if [[ -z "${color}" ]]; then
  echo "Unable to determine active color from service/web selector in namespace ${NAMESPACE}" >&2
  exit 1
fi

echo "${color}"
