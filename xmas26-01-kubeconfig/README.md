# XMAS26 1/5 — Santa can't reach his own cluster

```
$ kubectl get pods -n reindeer
The connection to the server localhost:8080 was refused - did you specify the right host or port?
```

The cluster is fine. `localhost:8080` is kubectl's fallback when it finds **no kubeconfig at all** — no `KUBECONFIG` variable, no `~/.kube/config`.

- Short: <!-- TODO: YouTube link -->

## Run the lab

```bash
./setup.sh                                 # kind cluster "sleigh-prod" (shared by all XMAS26 labs)
docker exec -it sleigh-prod-control-plane bash
kubectl get pods -n reindeer               # -> localhost:8080 refused
```

**Task:** make `kubectl` on the control-plane node talk to the cluster, using the context `sleigh-prod`. Then run `./verify.sh` on your machine.

<details><summary>Hints</summary>

- kubeadm writes an admin kubeconfig to `/etc/kubernetes/`.
- `kubectl config get-contexts` shows which context is marked with `*`.
</details>

<details><summary>Solution</summary>

```bash
export KUBECONFIG=/etc/kubernetes/admin.conf   # kubeadm control plane
kubectl config get-contexts                     # * sleigh-staging
kubectl config use-context sleigh-prod
kubectl get pods -n reindeer
```
</details>

## CKA tip

Every exam task starts with a context command. Copy it. Every. Single. Time. Perfect YAML on the wrong cluster still scores 0.

Clean up after the last XMAS26 lab: `kind delete cluster --name sleigh-prod`
