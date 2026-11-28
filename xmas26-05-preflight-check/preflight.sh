#!/usr/bin/env bash
# XMAS26 5/5 — five checks before take-off, in the order of the doors
set -uo pipefail
step() { printf '\n\033[1;34m### %s\033[0m\n' "$*"; }

step "1. Right cluster, nodes Ready (door 1)"
kubectl config current-context
kubectl get nodes
step "2. Restarts per pod (door 2)"
kubectl get pods -A -o 'custom-columns=POD:.metadata.name,RESTARTS:.status.containerStatuses[*].restartCount'
step "3. Pods neither Running nor Succeeded (door 3)"
kubectl get pods -A --field-selector=status.phase!=Running,status.phase!=Succeeded
step "4. The app reaches its database by name (door 4)"
kubectl -n paddock exec deploy/reindeer -- pg_isready -h sleigh-db
step "5. Warning events"
kubectl events -A --types=Warning
