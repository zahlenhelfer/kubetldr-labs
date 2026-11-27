#!/usr/bin/env bash
# XMAS26 4/5 — technical check of the lockdown lab on a real kind cluster.
# Run from kubetldr-labs/xmas26-04-netpol-dns AFTER ./setup.sh (broken state).
set -uo pipefail
NS=paddock
hr() { printf '\n\033[1;34m## %s\033[0m\n' "$*"; }

hr "kind + kindnet (NetworkPolicy enforcement needs kind >= v0.24)"
kind version
kubectl -n kube-system get ds kindnet -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'
for n in $(kind get nodes --name sleigh-prod); do
  printf '%s: ' "$n"
  docker exec "$n" nft list tables 2>/dev/null | grep -q kindnet-network-policies \
    && echo "netpol nft table present" || echo "no netpol nft table (controller not running here?)"
done

hr "Policies in kube-system (expect none -> CoreDNS is not isolated for ingress)"
kubectl -n kube-system get networkpolicy

kubectl get namespace "$NS" >/dev/null 2>&1 \
  || { echo "Namespace $NS not found: run ./setup.sh first, then re-run this check."; exit 1; }
kubectl -n "$NS" rollout status deploy/reindeer --timeout=120s >/dev/null || exit 1

SVC_IP=$(kubectl -n $NS get svc sleigh-db -o jsonpath='{.spec.clusterIP}')
POD_IP=$(kubectl -n $NS get pod -l app=sleigh-db -o jsonpath='{.items[0].status.podIP}')

hr "By name (expect: could not translate host name ... Try again, after ~5 s)"
# shellcheck disable=SC2016  # expands inside the pod, not here
kubectl -n $NS exec deploy/reindeer -- sh -c \
  's=$(date +%s); psql -h sleigh-db -U postgres -tAc "select 1" 2>&1; echo "took $(( $(date +%s)-s ))s"'

hr "By Service IP $SVC_IP (expect ok -> policy is evaluated after DNAT)"
kubectl -n $NS exec deploy/reindeer -- psql -h "$SVC_IP" -U postgres -tAc "select 'by service IP ok'"

hr "By pod IP $POD_IP (expect ok)"
kubectl -n $NS exec deploy/reindeer -- psql -h "$POD_IP" -U postgres -tAc "select 'by pod IP ok'"

hr "Apply the fix and poll the app log (no fixed sleep: one loop = up to 5 s DNS timeout + 5 s sleep)"
kubectl apply -f lockdown-fixed.yaml
for i in $(seq 1 12); do
  if kubectl -n $NS logs deploy/reindeer --tail=1 | grep -q "sleigh-db ok"; then
    echo "OK: by name after ~$((i * 5)) s"; break
  fi
  sleep 5
done
kubectl -n $NS logs deploy/reindeer --tail=1

hr "Restore the broken state for recording"
kubectl apply -f lockdown.yaml
