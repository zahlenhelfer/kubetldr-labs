# kube tl;dr — labs

Hands-on companion repo for the **kube tl;dr** YouTube Shorts and the blog *Tales from Dev(Sec)Ops-Land*.
Every episode folder contains the manifests and a lab script that reproduces what you see in the short — on a throwaway [kind](https://kind.sigs.k8s.io/) cluster.

| Episode | Topic | Folder |
|---|---|---|
| EP01 | `kubectl create` vs. `kubectl apply` | [`ep01-create-vs-apply`](ep01-create-vs-apply/) |
| EP02 | `kubectl debug` and distroless | [`ep02-kubectl-debug`](ep02-kubectl-debug/) (coming soon) |

### XMAS26 Advent Edition

Five troubleshooting labs on one shared kind cluster `sleigh-prod` (1 control plane + 2 workers, created by the first `setup.sh` you run). Each folder: `setup.sh` (breaks it), `README.md` (task, hints, solution), `verify.sh`.

| Short | Release | Topic | Folder |
|---|---|---|---|
| XMAS26 1/5 | 1st Advent, Nov 29 | `localhost:8080 refused` — no kubeconfig | [`xmas26-01-kubeconfig`](xmas26-01-kubeconfig/) |
| XMAS26 2/5 | 2nd Advent, Dec 6 | CrashLoopBackOff — `kubectl logs --previous` | [`xmas26-02-crashloop-previous`](xmas26-02-crashloop-previous/) |
| XMAS26 3/5 | 3rd Advent, Dec 13 | Pending — requests, not usage | [`xmas26-03-pending-requests`](xmas26-03-pending-requests/) |
| XMAS26 4/5 | 4th Advent, Dec 20 | NetworkPolicy lockdown blocks DNS | [`xmas26-04-netpol-dns`](xmas26-04-netpol-dns/) |
| XMAS26 5/5 | Christmas Eve | Final check before take-off | [`xmas26-05-preflight-check`](xmas26-05-preflight-check/) |

## Requirements

- `kubectl` (recent; episodes note when a minimum version matters)
- `kind` plus Docker or Podman

## Found a mistake?

Open an issue — Kubernetes changes, and outputs drift between versions.

## License

Apache-2.0, see [LICENSE](LICENSE).
