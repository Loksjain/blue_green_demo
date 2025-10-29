#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: $0 <color> [namespace]" >&2
  exit 1
fi

COLOR="$1"
NAMESPACE="${2:-blue-green-demo}"
DEPLOYMENT="web-${COLOR}"

echo "Waiting for rollout of ${DEPLOYMENT} in namespace ${NAMESPACE}..."
kubectl rollout status "deployment/${DEPLOYMENT}" --namespace "${NAMESPACE}"
kubectl get pods --selector "app=blue-green-demo,color=${COLOR}" --namespace "${NAMESPACE}"
