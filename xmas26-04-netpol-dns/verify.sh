#!/usr/bin/env bash
set -uo pipefail
kubectl -n route-planner get networkpolicy lockdown >/dev/null 2>&1 || { echo "✘ keep the lockdown — fix it, don't delete it"; exit 1; }
sleep 8
if kubectl -n route-planner logs deploy/route-api --tail=1 | grep -q "route-db ok"; then
  echo "✔ route-api reaches route-db by name — lockdown still in place"
else
  echo "✘ route-api still can't reach route-db"; kubectl -n route-planner logs deploy/route-api --tail=1; exit 1
fi
