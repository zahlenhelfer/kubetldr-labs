#!/usr/bin/env bash
# XMAS26 5/5 — Final check before take-off
# Brings sleigh-prod into the "all green" state the short shows:
#   - the scenarios from 2/5–4/5 (if present) in their FIXED state
#   - the paddock from 4/5 with the fixed lockdown (check 4 needs it; created if missing)
#   - a "sleigh" namespace with a completed Job (shows why the field selector needs both conditions)
# Polls instead of fixed sleeps. Fails if the cluster cannot be green (e.g. old restarts in kube-system).
set -uo pipefail
cd "$(dirname "$0")" || exit 1
# shellcheck source=../xmas26-common/cluster.sh
. ../xmas26-common/cluster.sh
ensure_cluster

step "Load the sleigh (2 running pods + 1 completed Job)"
kubectl apply -f sleigh.yaml
kubectl -n sleigh rollout status deploy/sleigh-nav --timeout=120s
kubectl -n sleigh wait --for=condition=complete job/load-gifts --timeout=120s

if kubectl -n reindeer get deploy reindeer-tracker >/dev/null 2>&1; then
  step "Door 2: reindeer-tracker gets its route API (fixed state of 2/5)"
  kubectl -n reindeer set env deploy/reindeer-tracker ROUTE_API_URL=http://route-api:8080
  kubectl -n reindeer rollout status deploy/reindeer-tracker --timeout=120s
fi

if kubectl -n workshop get deploy toy-painter >/dev/null 2>&1; then
  step "Door 3: toy-painter requests one stool (fixed state of 3/5)"
  kubectl -n workshop set resources deploy/toy-painter --requests=cpu=1
  kubectl -n workshop rollout status deploy/toy-painter --timeout=120s
fi

step "Door 4: paddock with the second gate open (fixed state of 4/5)"
if ! kubectl -n paddock get deploy reindeer >/dev/null 2>&1; then
  ../xmas26-04-netpol-dns/setup.sh || fail "could not set up the paddock (4/5)"
fi
kubectl apply -f ../xmas26-04-netpol-dns/lockdown-fixed.yaml
reached=""
for _ in $(seq 1 30); do
  if kubectl -n paddock exec deploy/reindeer -- pg_isready -q -h sleigh-db -t 3 2>/dev/null; then reached=1; break; fi
  sleep 2
done
[ -n "$reached" ] || fail "the reindeer still can't reach sleigh-db by name"
kubectl -n paddock exec deploy/reindeer -- pg_isready -h sleigh-db

step "Clear old Warning events from the earlier labs (they would expire after 1 h anyway)"
kubectl delete events -A --field-selector type=Warning >/dev/null

step "Pre-flight: is everything green?"
red=0
restarts=$(kubectl get pods -A -o jsonpath='{range .items[*]}{.metadata.namespace}/{.metadata.name}{" "}{.status.containerStatuses[*].restartCount}{"\n"}{end}' \
  | awk '{s=0; for (i=2; i<=NF; i++) s+=$i; if (s>0) print "  " $1 " restarts=" s}')
if [ -n "$restarts" ]; then
  echo "✘ pods with restarts:"; echo "$restarts"; red=1
fi
stuck=$(kubectl get pods -A --field-selector=status.phase!=Running,status.phase!=Succeeded --no-headers 2>/dev/null)
if [ -n "$stuck" ]; then
  echo "✘ pods neither Running nor Succeeded:"; echo "$stuck"; red=1
fi
warnings=$(kubectl get events -A --field-selector type=Warning --no-headers 2>/dev/null)
if [ -n "$warnings" ]; then
  echo "✘ new Warning events:"; echo "$warnings"; red=1
fi
if [ "$red" -ne 0 ]; then
  fail "not green. Restart counts can't be reset — for a clean run: kind delete cluster --name $CLUSTER && ./setup.sh"
fi
ok "All green. Run ./preflight.sh"

step "Why the comma matters — plain !=Running also lists the finished Job:"
kubectl get pods -n sleigh --field-selector=status.phase!=Running
