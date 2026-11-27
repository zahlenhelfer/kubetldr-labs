#!/usr/bin/env bash
set -uo pipefail
if kubectl -n workshop rollout status deploy/toy-painter --timeout=60s >/dev/null; then
  req=$(kubectl -n workshop get deploy toy-painter -o jsonpath='{.spec.template.spec.containers[0].resources.requests.cpu}')
  echo "✔ toy-painter scheduled and running (cpu request: $req)"
else
  echo "✘ still Pending"; kubectl -n workshop get pods; exit 1
fi
