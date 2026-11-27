#!/usr/bin/env bash
# XMAS26 4/5 — The lockdown: egress only to the sleighs (databases), and DNS breaks
set -uo pipefail
cd "$(dirname "$0")" || exit 1
# shellcheck source=../xmas26-common/cluster.sh
. ../xmas26-common/cluster.sh
require_kind_netpol
ensure_cluster

# earlier versions of this lab used the namespace route-planner
kubectl delete namespace route-planner --ignore-not-found --wait=false >/dev/null

step "Deploy the paddock: reindeer (app) + two sleighs (Postgres)"
kubectl create namespace paddock --dry-run=client -o yaml | kubectl apply -f -
kubectl delete networkpolicy lockdown -n paddock --ignore-not-found >/dev/null
kubectl apply -f sleigh-yard.yaml
for d in sleigh-db spare-sleigh reindeer; do
  kubectl -n paddock rollout status "deploy/$d" --timeout=180s
done
wait_for_log paddock reindeer "sleigh-db ok" 60 || fail "reindeer can't reach sleigh-db even without the lockdown"
kubectl -n paddock logs deploy/reindeer --tail=1

step "Apply the lockdown NetworkPolicy"
kubectl apply -f lockdown.yaml
if wait_for_log paddock reindeer "could not translate host name" 60; then
  ok "Reproduced. Start with: kubectl logs deploy/reindeer -n paddock --tail=3"
else
  fail "DNS still resolves — is NetworkPolicy enforced? (kindnet enforces it since kind v0.24)"
fi
