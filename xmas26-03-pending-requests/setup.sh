#!/usr/bin/env bash
# XMAS26 3/5 — Pending all night: idle nodes, still "Insufficient cpu"
set -uo pipefail
cd "$(dirname "$0")" || exit 1
# shellcheck source=../xmas26-common/cluster.sh
. ../xmas26-common/cluster.sh
ensure_cluster

step "Worker allocatable CPU"
kubectl get nodes -o custom-columns=NODE:.metadata.name,CPU:.status.allocatable.cpu
alloc=$(kubectl get node "$CLUSTER-worker" -o jsonpath='{.status.allocatable.cpu}')
case "$alloc" in *m) alloc_m=${alloc%m} ;; *) alloc_m=$((alloc * 1000)) ;; esac
[ "$alloc_m" -lt 4000 ] || echo "⚠ workers have $alloc CPUs — 'cpu: 4' may fit. Recreate the cluster with WORKER_CPUS=2."

step "Deploy route-optimizer (requests cpu: 4)"
kubectl create namespace route-planner --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f route-optimizer.yaml
sleep 5
kubectl -n route-planner get pods
ok "Start with: kubectl describe pod -n route-planner -l app=route-optimizer"
