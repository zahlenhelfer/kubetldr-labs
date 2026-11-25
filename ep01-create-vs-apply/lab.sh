#!/usr/bin/env bash
# kube tl;dr EP01 — kubectl create vs. kubectl apply
# Runs every case from the short and the blog post against a throwaway kind cluster.
set -uo pipefail
cd "$(dirname "$0")" || exit 1
CLUSTER=${CLUSTER:-create-vs-apply}
step() { printf '\n\033[1;34m### %s\033[0m\n' "$*"; }

step "Create a kind cluster ($CLUSTER)"
kind get clusters | grep -qx "$CLUSTER" || kind create cluster --name "$CLUSTER"
kubectl config use-context "kind-$CLUSTER" >/dev/null
cp web.yaml /tmp/web.yaml

step "1. kubectl create twice -> second run fails with AlreadyExists"
kubectl create -f /tmp/web.yaml
kubectl create -f /tmp/web.yaml; echo "exit code: $?"

step "2. kubectl apply on a created object -> missing-annotation warning"
kubectl apply -f /tmp/web.yaml

step "3. Clean declarative lifecycle: created -> configured -> unchanged"
kubectl delete -f /tmp/web.yaml --wait
kubectl apply -f /tmp/web.yaml
sed -i.bak 's/replicas: 2/replicas: 5/' /tmp/web.yaml
kubectl diff -f /tmp/web.yaml
kubectl apply -f /tmp/web.yaml
kubectl apply -f /tmp/web.yaml

step "4. The memory: last-applied-configuration"
kubectl get deploy web -o jsonpath='{.metadata.annotations.kubectl\.kubernetes\.io/last-applied-configuration}'; echo

step "5. Server-side apply and field managers"
kubectl apply --server-side -f /tmp/web.yaml
kubectl get deploy web -o yaml --show-managed-fields | grep -A3 "manager:"

step "Done. Clean up with: kind delete cluster --name $CLUSTER"
