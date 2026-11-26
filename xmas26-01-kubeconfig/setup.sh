#!/usr/bin/env bash
# XMAS26 1/5 — "The connection to the server localhost:8080 was refused"
# Prepares the control-plane node: no kubeconfig for root, and an admin.conf
# with two contexts (sleigh-staging = current, sleigh-prod).
set -uo pipefail
cd "$(dirname "$0")" || exit 1
# shellcheck source=../xmas26-common/cluster.sh
. ../xmas26-common/cluster.sh
ensure_cluster
NODE="$CLUSTER-control-plane"

step "Workload: namespace reindeer with two pods"
kubectl create namespace reindeer --dry-run=client -o yaml | kubectl apply -f -
kubectl -n reindeer create deployment sleigh-bells --image=registry.k8s.io/pause:3.10 --replicas=2 --dry-run=client -o yaml | kubectl apply -f -

step "Node $NODE: remove root's kubeconfig, add contexts to admin.conf"
docker exec "$NODE" bash -c '
  set -e
  rm -f /root/.kube/config
  export KUBECONFIG=/etc/kubernetes/admin.conf
  # kind names the admin context after the cluster (kubernetes-admin@sleigh-prod);
  # older images use kubernetes-admin@kubernetes. Rename whatever it is to sleigh-prod.
  if ! kubectl config get-contexts -o name | grep -qx sleigh-prod; then
    admin=$(kubectl config get-contexts -o name | grep -vx sleigh-staging | head -1)
    kubectl config rename-context "$admin" sleigh-prod >/dev/null
  fi
  # sleigh-staging: a second, unreachable cluster, so the context choice matters
  kubectl config set-cluster sleigh-staging --server=https://10.0.0.20:6443 --insecure-skip-tls-verify=true >/dev/null
  user=$(kubectl config view -o jsonpath="{.contexts[?(@.name==\"sleigh-prod\")].context.user}")
  kubectl config set-context sleigh-staging --cluster=sleigh-staging --user="$user" --namespace=default >/dev/null
  kubectl config use-context sleigh-staging >/dev/null
'
if docker exec "$NODE" printenv KUBECONFIG >/dev/null 2>&1; then
  echo "⚠ the node image sets KUBECONFIG — start the shell with: docker exec -it -e KUBECONFIG= $NODE bash"
fi
ok "Ready. Open a shell on the control plane and start the task:"
echo "  docker exec -it -e KUBECONFIG= $NODE bash"
echo "  kubectl get pods -n reindeer"
