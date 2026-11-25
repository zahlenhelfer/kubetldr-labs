# kube tl;dr — labs

Hands-on companion repo for the **kube tl;dr** YouTube Shorts and the blog *Tales from Dev(Sec)Ops-Land*.
Every episode folder contains the manifests and a lab script that reproduces what you see in the short — on a throwaway [kind](https://kind.sigs.k8s.io/) cluster.

| Episode | Topic | Folder |
|---|---|---|
| EP01 | `kubectl create` vs. `kubectl apply` | [`ep01-create-vs-apply`](ep01-create-vs-apply/) |
| EP02 | `kubectl debug` and distroless | [`ep02-kubectl-debug`](ep02-kubectl-debug/) (coming soon) |

## Requirements

- `kubectl` (recent; episodes note when a minimum version matters)
- `kind` plus Docker or Podman

## Found a mistake?

Open an issue — Kubernetes changes, and outputs drift between versions.

## License

Apache-2.0, see [LICENSE](LICENSE).
