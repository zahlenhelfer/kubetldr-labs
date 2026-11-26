# XMAS26 5/5 — Final check before take-off

Dec 24, 17:00. The sleigh is loaded. Five commands before take-off:

```bash
kubectl get nodes
kubectl get pods -A --field-selector=status.phase!=Running,status.phase!=Succeeded
kubectl get events -A --sort-by=.lastTimestamp | tail
kubectl get pods -A -o custom-columns=NS:.metadata.namespace,POD:.metadata.name,RESTARTS:.status.containerStatuses[*].restartCount
kubectl get nodes -o jsonpath='{.items[*].status.nodeInfo.kubeletVersion}'
```

- Short: <!-- TODO: YouTube link -->

## Run the lab

```bash
./setup.sh       # loads a "sleigh" namespace incl. a completed Job
./preflight.sh   # the five checks
```

- **#2:** the comma is an AND. `status.phase!=Running` alone also lists every completed Job pod (`Succeeded`).
- **#4:** quote the custom-columns argument in zsh — `[*]` is a glob there.
- If you ran XMAS26 2/5–4/5 without fixing them, #2 and #4 will tell you.

## Three lessons from five doors

1. Read events and logs before you change anything.
2. Most outages were one small thing: a kubeconfig, an env var, a request, a DNS rule.
3. Fundamentals beat tools.

## CKA tip

Practice `-o jsonpath` and `custom-columns`. They turn a wall of YAML into one answer.

Clean up: `kind delete cluster --name sleigh-prod`
