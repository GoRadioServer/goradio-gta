# Kubernetes

Example manifests live in `k8s/` — ConfigMap, Secret template, and
Deployment.

```sh
cp k8s/secret.example.yaml k8s/secret.yaml   # fill in a real JWT -- gitignored, never commit it
kubectl apply -f k8s/configmap.yaml -f k8s/secret.yaml -f k8s/deployment.yaml
```

## No Service needed

Unlike most deployments, there's nothing to expose. `api.enabled: false`
in the ConfigMap means nothing in the pod listens for inbound traffic —
it only dials *out* to `server.grpc_addr`. No `Service`, no `Ingress`.

## The Secret

```sh
GORADIO_JWT_SECRET=<the audio server's auth.jwt_secret> ./scripts/mint-token.sh
```

mints the token (see
[Prerequisites](../getting-started/prerequisites.md#2-a-jwt-authorizing-every-station-slug)).
Paste the result into `k8s/secret.yaml`'s `stringData.jwt` — start from
`k8s/secret.example.yaml`, which is real-secret-free and safe to commit;
`secret.yaml` itself is gitignored.

## The ConfigMap

Mirrors `station.yaml`, minus the JWT — `auth.jwt` stays empty there,
since the real token comes from the Secret's `GORADIO_JWT` environment
variable instead, which the running process prefers over the mounted
file's value either way.

## Replicas

Each of the forty stations registers itself once, on boot. Running more
than one replica of this Deployment means running all forty a second
time — a second controller trying to register the same slug. Leave
`replicas: 1` unless you've built coordination on top of this image to
split the station list across replicas yourself; nothing here does that
for you.
