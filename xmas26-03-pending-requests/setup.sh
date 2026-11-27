#!/usr/bin/env bash
# XMAS26 3/5 — Pending all night: idle nodes, still "Insufficient cpu"
# Each worker offers 4 CPUs (one workbench = 4 stools). gift-wrapper books ~3 of them on every worker
# but stays idle; toy-painter asks for 2 CPUs and stays Pending although `kubectl top nodes` shows idle workers.
set -uo pipefail
cd "$(dirname "$0")" || exit 1
# shellcheck source=../xmas26-common/cluster.sh
. ../xmas26-common/cluster.sh
ensure_cluster

METRICS_SERVER_VERSION=${METRICS_SERVER_VERSION:-v0.9.0}
FREE_TARGET_M=1200   # CPU left on a worker after gift-wrapper: 1 CPU fits, 2 CPUs don't

to_m() { case "$1" in *m) echo "${1%m}" ;; *) echo $(( $1 * 1000 )) ;; esac; }   # "1500m" | "2" -> millicores
booked_m() {   # CPU requests already booked on a node, exactly as "kubectl describe node" shows them
  to_m "$(kubectl describe node "$1" | awk '/^Allocated resources:/{f=1} f && $1=="cpu"{print $2; exit}')"
}

step "Workers: 4 allocatable CPUs each (1 stool = 1 CPU)"
kubectl get nodes -o custom-columns=NODE:.metadata.name,CPU:.status.allocatable.cpu
workers=$(kubectl get nodes -l '!node-role.kubernetes.io/control-plane' -o jsonpath='{.items[*].metadata.name}')
for n in $workers; do
  a=$(to_m "$(kubectl get node "$n" -o jsonpath='{.status.allocatable.cpu}')")
  [ "$a" -eq 4000 ] || fail "$n offers ${a}m CPU, expected 4000m. Recreate the cluster (Docker needs >= 4 CPUs): kind delete cluster --name $CLUSTER && ./setup.sh"
done

step "metrics-server $METRICS_SERVER_VERSION (on the control plane, so it books no worker CPU)"
if ! kubectl -n kube-system get deploy metrics-server >/dev/null 2>&1; then
  kubectl apply -f "https://github.com/kubernetes-sigs/metrics-server/releases/download/$METRICS_SERVER_VERSION/components.yaml" >/dev/null
  kubectl -n kube-system patch deploy metrics-server --type=json -p '[
    {"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"},
    {"op": "add", "path": "/spec/template/spec/nodeSelector/node-role.kubernetes.io~1control-plane", "value": ""},
    {"op": "add", "path": "/spec/template/spec/tolerations",
     "value": [{"key": "node-role.kubernetes.io/control-plane", "operator": "Exists", "effect": "NoSchedule"}]}]' >/dev/null
fi
kubectl -n kube-system rollout status deploy/metrics-server --timeout=180s || fail "metrics-server did not become ready"
for _ in $(seq 1 24); do kubectl top nodes >/dev/null 2>&1 && break; sleep 5; done
kubectl top nodes >/dev/null 2>&1 || fail "kubectl top nodes still has no metrics"

step "Fresh namespace workshop"
kubectl delete namespace workshop --ignore-not-found --wait=true >/dev/null
kubectl create namespace workshop

step "gift-wrapper books most of every workbench (and stays idle)"
max_free=0; min_free=4000
for n in $workers; do
  free=$(( 4000 - $(booked_m "$n") ))
  [ "$free" -gt "$max_free" ] && max_free=$free
  [ "$free" -lt "$min_free" ] && min_free=$free
done
wrap_m=$(( max_free - FREE_TARGET_M ))
[ $(( min_free - wrap_m )) -ge 1000 ] || fail "workers differ too much in booked CPU (free: ${min_free}m..${max_free}m) — recreate the cluster"
sed "s/__WRAP_CPU__/${wrap_m}m/" gift-wrapper.yaml.tmpl | kubectl apply -f -
kubectl -n workshop rollout status ds/gift-wrapper --timeout=120s

step "Deploy toy-painter (requests cpu: 2)"
kubectl apply -f toy-painter.yaml
sleep 5
kubectl -n workshop get pods
kubectl top nodes
ok "Start with: kubectl describe pod -n workshop -l app=toy-painter"
