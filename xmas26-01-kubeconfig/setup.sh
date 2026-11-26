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
  if kubectl config get-contexts -o name | grep -qx kubernetes-admin@kubernetes; then
    kubectl config rename-context kubernetes-admin@kubernetes sleigh-prod >/dev/null
  fi
  kubectl config set-context sleigh-staging --cluster=kubernetes --user=kubernetes-admin --namespace=default >/dev/null
  kubectl config use-context sleigh-staging >/dev/null
'
ok "Ready. Open a shell on the control plane and start the task:"
echo "  docker exec -it $NODE bash"
echo "  kubectl get pods -n reindeer"
