# XMAS26 3/5 — Pending all night

```
Warning  FailedScheduling  0/3 nodes are available: 1 node(s) had untolerated taint(s), 2 Insufficient cpu.
```

The nodes are idle. So why?

- Short: <!-- TODO: YouTube link -->

## Run the lab

```bash
./setup.sh      # the shared cluster reserves CPU so each worker offers 2 CPUs (WORKER_CPUS=2)
```

**Task:** get `route-optimizer` scheduled. It really only needs half a CPU. Then `./verify.sh`.

> The workers are kind containers on your machine. `ensure_cluster` sets the workers' kubelet `--system-reserved` CPU so that each worker's **allocatable** CPU is 2 — like the 2-CPU workers in the story.

<details><summary>Solution</summary>

The scheduler places pods by **requests**, not usage. `cpu: 4` doesn't fit a 2-CPU worker. The untolerated taint is the control plane — the event doesn't name it, `kubectl describe node` does.

```bash
kubectl describe node sleigh-prod-worker | grep -A 8 "Allocated resources"
kubectl describe node sleigh-prod-control-plane | grep Taints
kubectl set resources deploy/route-optimizer -n route-planner --requests=cpu=500m
```
</details>

## CKA tip

Scheduling = requests. Limits are never used for placement. `Insufficient cpu` on idle nodes? Sum up the requests, don't trust `top`.
