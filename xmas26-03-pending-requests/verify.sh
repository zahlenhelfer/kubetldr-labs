#!/usr/bin/env bash
set -uo pipefail
if kubectl -n route-planner rollout status deploy/route-optimizer --timeout=60s >/dev/null; then
  echo "✔ route-optimizer scheduled and running"
else
  echo "✘ still Pending"; kubectl -n route-planner get pods; exit 1
fi
