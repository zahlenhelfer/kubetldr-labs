#!/usr/bin/env bash
set -uo pipefail
NODE="${CLUSTER:-sleigh-prod}-control-plane"
ctx=$(docker exec "$NODE" bash -c 'KUBECONFIG=/etc/kubernetes/admin.conf kubectl config current-context')
[ "$ctx" = "sleigh-prod" ] || { echo "✘ current context is '$ctx', expected sleigh-prod"; exit 1; }
docker exec "$NODE" bash -c 'KUBECONFIG=/etc/kubernetes/admin.conf kubectl get pods -n reindeer --no-headers' | grep -q Running \
  || { echo "✘ no Running pods in reindeer"; exit 1; }
echo "✔ Right cluster, right context: sleigh-prod"
