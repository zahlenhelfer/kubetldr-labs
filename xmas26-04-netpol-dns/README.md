# XMAS26 4/5 — The lockdown

Santa fenced in the `paddock` namespace: a NetworkPolicy allows egress only to the sleighs (two Postgres databases), port 5432. The `reindeer` app asks for its sleigh by name — `sleigh-db` is running, the port is allowed, so it should work. And the app logs:

```
could not translate host name "sleigh-db"
```

- Short: <!-- TODO: YouTube link -->

## Run the lab

Requires NetworkPolicy enforcement — kind's default CNI (kindnet) enforces it since kind v0.24 (`setup.sh` checks this).

```bash
./setup.sh
```

**Task:** fix the policy (keep the lockdown!) so `reindeer` reaches `sleigh-db` by name. Then `./verify.sh`.

The app logs psql's message without the `psql: error:` prefix and the `to address: …` tail (the full text is `could not translate host name "sleigh-db" to address: Try again`).

| In the short | In the cluster |
|---|---|
| reindeer | pod `reindeer` |
| sleighs | pods `sleigh-db`, `spare-sleigh` (label `tier: sleigh`) |
| Santa's fence | NetworkPolicy `lockdown` (`podSelector: {}` = the whole paddock) |
| directory elf | CoreDNS (`k8s-app: kube-dns` in `kube-system`) |
| bay number | IP |

<details><summary>Hint: IP vs. name</summary>

```bash
SVC_IP=$(kubectl -n paddock get svc sleigh-db -o jsonpath='{.spec.clusterIP}')
kubectl -n paddock exec deploy/reindeer -- pg_isready -h "$SVC_IP"
kubectl -n paddock exec deploy/reindeer -- pg_isready -h sleigh-db
```
`accepting connections` by IP, `no response` by name → it's DNS. The DNS lookup is egress too, and the lockdown doesn't list it.
</details>

<details><summary>Solution</summary>

Egress to CoreDNS is blocked. Add a second egress rule — both selectors in **one** list item = AND:

```yaml
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: kube-system
      podSelector:
        matchLabels:
          k8s-app: kube-dns
    ports:
    - protocol: UDP
      port: 53
    - protocol: TCP
      port: 53
```

Full policy: [`lockdown-fixed.yaml`](lockdown-fixed.yaml) → `kubectl apply -f lockdown-fixed.yaml`
</details>

## Why it works this way

- **AND vs. OR:** split into two list items (`- namespaceSelector …` and `- podSelector …`), the rule would allow *every* pod in `kube-system` *or* pods labeled `k8s-app: kube-dns` in `paddock` — DNS works, but the gate is far too wide.
- **No ingress rule in `kube-system` needed:** a pod is only isolated for ingress if a policy with `Ingress` in `policyTypes` selects it. Nothing selects CoreDNS, and replies to allowed connections are allowed implicitly. (A hardened cluster with a default-deny in `kube-system` would need an ingress allow there too.)
- **Ports are pod ports:** kindnet evaluates policies after the Service DNAT, so the rule sees the CoreDNS pod and its port. On a platform where the DNS pods listen on another port than the Service (e.g. 5353), allow that port.
- **Technical check:** [`check-04.sh`](check-04.sh) (run after `./setup.sh`) tests by name, by Service IP and by pod IP, applies the fix and restores the broken state.

## CKA tip

IP works, name fails? Check egress on port 53. And an empty `podSelector: {}` selects ALL pods in the namespace — had the policy also listed `Ingress` without ingress rules, the sleighs would reject the reindeer too.
