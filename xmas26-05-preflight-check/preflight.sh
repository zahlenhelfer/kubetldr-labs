#!/usr/bin/env bash
# XMAS26 5/5 — the five one-liners before take-off
set -uo pipefail
step() { printf '\n\033[1;34m### %s\033[0m\n' "$*"; }

step "1. Nodes"
kubectl get nodes
step "2. Pods that are neither Running nor Succeeded (comma = AND)"
kubectl get pods -A --field-selector=status.phase!=Running,status.phase!=Succeeded
step "3. Latest events"
kubectl get events -A --sort-by=.lastTimestamp | tail
step "4. Restarts per pod"
kubectl get pods -A -o 'custom-columns=NS:.metadata.namespace,POD:.metadata.name,RESTARTS:.status.containerStatuses[*].restartCount'
step "5. Kubelet versions"
kubectl get nodes -o jsonpath='{.items[*].status.nodeInfo.kubeletVersion}'; echo
