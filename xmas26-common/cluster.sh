#!/usr/bin/env bash
# Shared helper for the XMAS26 labs: one kind cluster "sleigh-prod"
# (1 control plane + 2 workers), context renamed to "sleigh-prod".
# Source it from a lab script:  . "$(dirname "$0")/../xmas26-common/cluster.sh"
# Override: CLUSTER, NODE_IMAGE (e.g. kindest/node:v1.35.0), WORKER_CPUS (default 4).

CLUSTER=${CLUSTER:-sleigh-prod}
WORKER_CPUS=${WORKER_CPUS:-4}

step() { printf '\n\033[1;34m### %s\033[0m\n' "$*"; }
ok()   { printf '\033[1;32m✔ %s\033[0m\n' "$*"; }
fail() { printf '\033[1;31m✘ %s\033[0m\n' "$*"; exit 1; }

# kind nodes see all host CPUs. To make the workers look like 4-CPU machines
# (XMAS26 3/5: one workbench = 4 stools = 4 CPUs), reserve the rest via the kubelet's --system-reserved.
_reserved_cpus() {
  local host
  host=$(docker info --format '{{.NCPU}}' 2>/dev/null || nproc)
  if [ "$host" -gt "$WORKER_CPUS" ]; then echo $((host - WORKER_CPUS)); else echo 0; fi
}

ensure_cluster() {
  if ! kind get clusters 2>/dev/null | grep -qx "$CLUSTER"; then
    step "Create kind cluster $CLUSTER (1 control plane + 2 workers)"
    local reserved cfg
    reserved=$(_reserved_cpus)
    cfg=$(mktemp)
    cat > "$cfg" <<CFG
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
  - role: worker
    kubeadmConfigPatches:
      - |
        kind: JoinConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            system-reserved: "cpu=${reserved}"
  - role: worker
    kubeadmConfigPatches:
      - |
        kind: JoinConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            system-reserved: "cpu=${reserved}"
CFG
    [ "$reserved" -eq 0 ] && sed -i.bak '/kubeadmConfigPatches/,/system-reserved/d' "$cfg"
    kind create cluster --name "$CLUSTER" --config "$cfg" ${NODE_IMAGE:+--image "$NODE_IMAGE"} --wait 180s || fail "kind create cluster failed"
    rm -f "$cfg" "$cfg.bak"
  fi
  if kubectl config get-contexts -o name | grep -qx "kind-$CLUSTER"; then
    kubectl config delete-context "$CLUSTER" >/dev/null 2>&1 || true
    kubectl config rename-context "kind-$CLUSTER" "$CLUSTER" >/dev/null
  fi
  kubectl config use-context "$CLUSTER" >/dev/null
}
