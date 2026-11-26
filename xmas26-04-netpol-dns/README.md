# XMAS26 4/5 — The lockdown

Egress in `route-planner` is locked down — only the database is allowed. The DB pod is up, port 5432 is allowed. And the app logs:

```
psql: error: could not translate host name "route-db" to address: ...
```

- Short: <!-- TODO: YouTube link -->

## Run the lab

Requires NetworkPolicy enforcement — kind's default CNI (kindnet) enforces it since kind v0.24.

```bash
./setup.sh
```

**Task:** fix the policy (keep the lockdown!) so `route-api` reaches `route-db` by name. Then `./verify.sh`.

<details><summary>Hint: IP vs. name</summary>

```bash
SVC_IP=$(kubectl -n route-planner get svc route-db -o jsonpath='{.spec.clusterIP}')
kubectl -n route-planner exec deploy/route-api -- psql -h "$SVC_IP" -U postgres -tAc "select 'by IP ok'"
```
IP works, name fails → it's DNS.
</details>

<details><summary>Solution</summary>

Egress to CoreDNS is blocked. Add a second egress rule — both selectors in **one** list item = AND:

```yaml
    - to:
        - namespaceSelector: {matchLabels: {kubernetes.io/metadata.name: kube-system}}
          podSelector: {matchLabels: {k8s-app: kube-dns}}
      ports:
        - {protocol: UDP, port: 53}
        - {protocol: TCP, port: 53}
```

Full policy: [`lockdown-fixed.yaml`](lockdown-fixed.yaml) → `kubectl apply -f lockdown-fixed.yaml`
</details>

## CKA tip

An empty `podSelector: {}` selects ALL pods in the namespace. Had the policy also listed `Ingress` without ingress rules, `route-db` would reject the app too.
