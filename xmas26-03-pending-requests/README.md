# XMAS26 3/5 — Pending all night

```
Warning  FailedScheduling  0/3 nodes are available: 1 node(s) had untolerated taint(s), 2 Insufficient cpu.
```

`kubectl top nodes` says the workers are almost idle. So why?

- Short: <!-- TODO: YouTube link -->

## Run the lab

```bash
./setup.sh      # shared cluster: each worker offers 4 CPUs (WORKER_CPUS=4), metrics-server installed
```

The story: every node is a workbench with four stools, one stool = one CPU. A pod books its stools before it starts — that's the CPU request. The `gift-wrapper` pods booked about three stools on every bench and fell asleep (they run `pause`). The `toy-painter` wants two.

**Task:** get `toy-painter` scheduled. It really only needs one CPU. Then `./verify.sh`.

> The workers are kind containers on your machine. `ensure_cluster` sets the workers' kubelet `--system-reserved` CPU so that each worker's **allocatable** CPU is 4. Created the cluster with 2-CPU workers for an earlier version of this lab? `kind delete cluster --name sleigh-prod && ./setup.sh`.

<details><summary>Hints</summary>

- Compare `kubectl top nodes` with the **Allocated resources** section of `kubectl describe node`.
- Which node is the "untolerated taint"? `kubectl describe node` shows the taints.

</details>

<details><summary>Solution</summary>

The scheduler places pods by **requests**, not usage. Each worker has 4 CPUs allocatable, `gift-wrapper` has booked ~2.8 of them (incl. kindnet), so ~1.2 are left: `cpu: 2` doesn't fit, `cpu: 1` does. The untolerated taint is the control plane.

```bash
kubectl top nodes
kubectl describe node sleigh-prod-worker | grep -A 8 "Allocated resources"
kubectl describe node sleigh-prod-control-plane | grep Taints
kubectl set resources deploy/toy-painter -n workshop --requests=cpu=1     # 1 = 1000m
```

The other fix — right-sizing the over-booked `gift-wrapper` — is usually the better one in real clusters.
</details>

## CKA tip

Scheduling = requests. `Insufficient cpu` on idle nodes? Don't trust `top` — sum up the requests in **Allocated resources**. And if a container sets only a limit, Kubernetes copies the limit into the request, so the limit decides placement after all ([Resource Management for Pods and Containers](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)).
