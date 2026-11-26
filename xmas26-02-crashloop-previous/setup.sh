#!/usr/bin/env bash
# XMAS26 2/5 — CrashLoopBackOff, but the logs look healthy
set -uo pipefail
cd "$(dirname "$0")" || exit 1
# shellcheck source=../xmas26-common/cluster.sh
. ../xmas26-common/cluster.sh
ensure_cluster

step "Deploy reindeer-tracker (crashes ~30 s after start: ROUTE_API_URL missing)"
kubectl create namespace reindeer --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f reindeer-tracker.yaml

# Plain `kubectl logs` shows the CURRENT container. While the pod waits in
# CrashLoopBackOff, the current one is the dead one and its FATAL line is
# visible. The "healthy logs" moment is the window right after a restart.
step "Waiting until RESTARTS >= ${MIN_RESTARTS:-3} and the new attempt is running (~2-3 min)"
for _ in $(seq 1 120); do
  r=$(kubectl -n reindeer get pods -l app=reindeer-tracker -o jsonpath='{.items[0].status.containerStatuses[0].restartCount}' 2>/dev/null)
  run=$(kubectl -n reindeer get pods -l app=reindeer-tracker -o jsonpath='{.items[0].status.containerStatuses[0].state.running.startedAt}' 2>/dev/null)
  if [ "${r:-0}" -ge "${MIN_RESTARTS:-3}" ] && [ -n "$run" ]; then
    ok "restarts=$r, current attempt running — you have ~30 s for the healthy-looking logs"
    echo "  kubectl get pods -n reindeer"
    echo "  kubectl logs deploy/reindeer-tracker -n reindeer"
    exit 0
  fi
  sleep 2
done
fail "timed out waiting for the crash loop"
