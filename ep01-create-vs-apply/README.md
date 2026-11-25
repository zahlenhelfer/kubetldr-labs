# EP01 — `kubectl create` vs. `kubectl apply`

Same YAML, two commands, opposite behavior: `create` fails if the object exists, `apply` makes the cluster match the file (create if missing, patch only the diff, otherwise unchanged).

- Short: <!-- TODO: YouTube link -->
- Blog post: <!-- TODO: link to "kubectl create vs. kubectl apply: same YAML, opposite behavior" -->

## Run the lab

Requirements: [kind](https://kind.sigs.k8s.io/), `kubectl`, Docker or Podman.

```bash
./lab.sh                                   # creates kind cluster "create-vs-apply" if missing
kind delete cluster --name create-vs-apply # clean up
```

| Step | What you will see |
|---|---|
| 1 | second `kubectl create` → `AlreadyExists`, exit code 1 |
| 2 | `kubectl apply` on a created object → warning about the missing `last-applied-configuration` annotation |
| 3 | `apply` → `created`, `diff` preview, `configured`, `unchanged` |
| 4 | the `last-applied-configuration` annotation kubectl uses for the three-way merge |
| 5 | `apply --server-side` and the field managers in `managedFields` |

## Rule of thumb

`create` for one-shots in your pipeline, `apply` for config changes.
