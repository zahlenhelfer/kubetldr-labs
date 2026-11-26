#!/usr/bin/env bash
# XMAS26 5/5 — Final check before take-off
set -uo pipefail
cd "$(dirname "$0")" || exit 1
# shellcheck source=../xmas26-common/cluster.sh
. ../xmas26-common/cluster.sh
ensure_cluster

step "Load the sleigh (2 running pods + 1 completed Job)"
kubectl apply -f sleigh.yaml
kubectl -n sleigh rollout status deploy/sleigh-nav --timeout=120s
kubectl -n sleigh wait --for=condition=complete job/load-gifts --timeout=120s
step "Why the comma matters — plain !=Running also lists the finished Job:"
kubectl get pods -n sleigh --field-selector=status.phase!=Running
ok "Now run ./preflight.sh"
