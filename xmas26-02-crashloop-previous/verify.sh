#!/usr/bin/env bash
set -uo pipefail
kubectl -n reindeer rollout status deploy/reindeer-tracker --timeout=60s >/dev/null || { echo "✘ rollout not finished"; exit 1; }
sleep "${CRASH_AFTER:-30}"; sleep 5
if kubectl -n reindeer logs deploy/reindeer-tracker | grep -q "sleigh position synced"; then
  echo "✔ reindeer-tracker is syncing — no more restarts"
else
  echo "✘ still no route API configured"; exit 1
fi
