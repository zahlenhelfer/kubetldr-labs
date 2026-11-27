#!/usr/bin/env bash
set -uo pipefail
cd "$(dirname "$0")" || exit 1
# shellcheck source=../xmas26-common/cluster.sh
. ../xmas26-common/cluster.sh

types=$(kubectl -n paddock get networkpolicy lockdown -o jsonpath='{.spec.policyTypes}' 2>/dev/null) \
  || fail "keep the lockdown — fix it, don't delete it"
case "$types" in *Egress*) ;; *) fail "keep the lockdown — it must still restrict Egress" ;; esac

if wait_for_log paddock reindeer "sleigh-db ok" 60; then
  ok "reindeer reaches sleigh-db by name — lockdown still in place"
else
  kubectl -n paddock logs deploy/reindeer --tail=1
  fail "reindeer still can't reach sleigh-db by name"
fi
