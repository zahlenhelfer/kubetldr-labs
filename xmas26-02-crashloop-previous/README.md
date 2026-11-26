# XMAS26 2/5 — The reindeer that won't stop restarting

STATUS flips between `Error` and `CrashLoopBackOff`, RESTARTS keeps climbing — and the logs look perfectly healthy:

```
$ kubectl logs deploy/reindeer-tracker -n reindeer
starting reindeer-tracker v1.4 … syncing sleigh position
```

- Short: <!-- TODO: YouTube link -->

## Run the lab

```bash
./setup.sh      # reuses/creates kind cluster "sleigh-prod", waits until the crash loop is running
```

**Task:** find out why the tracker crashes and fix it (the route API lives at `http://route-api:8080`). Then `./verify.sh`.

> Timing matters: plain `kubectl logs` shows the **current** container. Right after a restart that is the fresh, healthy-looking attempt. While the pod waits in `CrashLoopBackOff`, the current container is the dead one — then you see the crash even without `--previous`.

<details><summary>Solution</summary>

```bash
kubectl logs deploy/reindeer-tracker -n reindeer --previous
# FATAL: env ROUTE_API_URL not set – cannot sync sleigh position
kubectl describe pod -n reindeer -l app=reindeer-tracker | grep -A4 "Last State"
# Last State: Terminated, Reason: Error, Exit Code: 1  -> the app crashed, not Kubernetes
kubectl set env deploy/reindeer-tracker -n reindeer ROUTE_API_URL=http://route-api:8080
```
</details>

## CKA tip

`Last State: Terminated, Exit Code: 1` means the app crashed. Without `-p` / `--previous` you only see the current attempt.
