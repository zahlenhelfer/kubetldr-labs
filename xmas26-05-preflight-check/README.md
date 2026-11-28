# XMAS26 5/5 — Final check before take-off

Christmas Eve. Before the sleigh takes off: five checks for your whole cluster — in the order of the four doors, plus a final look at the warnings.

```bash
kubectl get nodes                                    # 1 right cluster (see the prompt/context), all Ready
kubectl get pods -A -o 'custom-columns=POD:.metadata.name,RESTARTS:.status.containerStatuses[*].restartCount'   # 2 restarts
kubectl get pods -A --field-selector=status.phase!=Running,status.phase!=Succeeded                              # 3 stuck pods
kubectl -n paddock exec deploy/reindeer -- pg_isready -h sleigh-db                                              # 4 by name
kubectl events -A --types=Warning                                                                               # 5 warnings
```

- Short: <!-- TODO: YouTube link -->

## Run the lab

```bash
./setup.sh       # brings sleigh-prod into the green state (fixes 2/5–4/5 if present, sets up the paddock)
./preflight.sh   # the five checks
```

`setup.sh` fails if the cluster can't be green — restart counts can't be reset, so pods that restarted earlier (e.g. in `kube-system` after your laptop slept) need a fresh cluster: `kind delete cluster --name sleigh-prod && ./setup.sh`. It also deletes old `Warning` events from the earlier labs (they expire after one hour anyway).

## Why these five

| Check | What green looks like | Door |
|---|---|---|
| 1 `get nodes` | prompt shows `sleigh-prod`, all nodes `Ready` | 1/5 kubeconfig |
| 2 restarts | `0` everywhere | 2/5 CrashLoopBackOff |
| 3 phase filter | `No resources found` | 3/5 Pending |
| 4 `pg_isready` by name | `accepting connections` | 4/5 NetworkPolicy + DNS |
| 5 warning events | none | anything else |

- **Why check 2 and check 3?** `CrashLoopBackOff` is only what `kubectl get pods` shows in the STATUS column — the pod's *phase* stays `Running` ("at least one container is still running, or is in the process of starting or restarting", [Pod Lifecycle](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#pod-phase)). The phase filter can't see a crash loop; the restart count can.
- **The comma is an AND.** `status.phase!=Running` alone also lists every completed Job pod (`Succeeded`) — `setup.sh` ends by showing it with `job/load-gifts`.
- **Quote the custom-columns argument in zsh** — `[*]` is a glob there (`no matches found`).
- **Check 4 is a smoke test from where the app runs.** Generic version: `kubectl -n <ns> run dns-check --rm -it --restart=Never --image=busybox:1.37 -- nslookup <service>`.
- **`kubectl events`** (GA since kubectl 1.27) is the newer form of `kubectl get events`; `--types=Warning` filters by type.
- **Bonus (not in the short):** kubelet versions with jsonpath — `kubectl get nodes -o jsonpath='{.items[*].status.nodeInfo.kubeletVersion}'`. The `VERSION` column of `kubectl get nodes` shows the same; it matters during upgrades (kubelet must not be newer than the API server and may be up to three minor versions older — [version skew policy](https://kubernetes.io/releases/version-skew-policy/)).

## Four doors, four small things

A kubeconfig, an environment variable, a request, a DNS rule.

## CKA tip

Start every task with the context — and end it with a check.

Clean up: `kind delete cluster --name sleigh-prod`
