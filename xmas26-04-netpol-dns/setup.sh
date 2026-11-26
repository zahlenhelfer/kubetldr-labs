#!/usr/bin/env bash
# XMAS26 4/5 — The lockdown: egress only to the database, and DNS breaks
set -uo pipefail
cd "$(dirname "$0")" || exit 1
# shellcheck source=../xmas26-common/cluster.sh
. ../xmas26-common/cluster.sh
ensure_cluster

step "Deploy route-db (Postgres) and route-api (psql loop)"
kubectl create namespace route-planner --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f route-planner.yaml
kubectl -n route-planner rollout status deploy/route-db --timeout=180s
kubectl -n route-planner rollout status deploy/route-api --timeout=180s
sleep 8
kubectl -n route-planner logs deploy/route-api --tail=1

step "Apply the lockdown NetworkPolicy"
kubectl apply -f lockdown.yaml
sleep 12
if kubectl -n route-planner logs deploy/route-api --tail=1 | grep -q "could not translate host name"; then
  ok "Reproduced. Start with: kubectl logs deploy/route-api -n route-planner --tail=3"
else
  echo "⚠ DNS still resolves — is NetworkPolicy enforced? kind's default CNI (kindnet) enforces it since kind v0.24."
fi
