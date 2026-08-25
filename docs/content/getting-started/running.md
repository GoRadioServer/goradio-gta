# Running with Docker

## Get the source

```sh
git clone https://github.com/GoRadioServer/goradio-gta
cd goradio-gta
```

## Audio layout

Before building or running anything, lay your own extracted `.ogg` files
out under `data/audio/` like this:

```
data/audio/
  GTASA/
    KROSE/
      All My Exes Live in Texas (Mid).ogg
      All My Exes Live in Texas (Intro DJ #1).ogg
      All My Exes Live in Texas (Outro).ogg
      ...
    Radio X/
      ...
    Adverts/
      'Intergalactic Wrestling Championship' on Weazel.ogg
      ...
  GTA3/
    Head Radio/
      ...
  GTAVC/
    Flash FM/
      ...
```

The top-level folder is the game (`GTASA`, `GTA3`, `GTAVC`), the next
level is each station's `audio_dir` — a real directory name, not the
slug (K-Rose's is `KROSE`; most others are the station's display name,
spaces and all — see [Station Data Format](../stations/data-format.md)
for the exact field). `GTASA/Adverts/` is shared across every San Andreas
station. Filenames must match exactly what each station's
`data/stations/<slug>.json` references — see that file's `songs[].intros`/
`.middle`/`.outros`, `idents`, `callers`, and `chatter` arrays for the
literal names to match.

`data/audio/` is gitignored — it never ships in the repo or the built
image (see the `.dockerignore` comment on why: it would otherwise bloat
every build context for nothing). It only needs to exist on the host
you're building from, or be mounted into a running container.

## Get a token

Following [Prerequisites](prerequisites.md#2-a-jwt-authorizing-every-station-slug):

```sh
GORADIO_JWT_SECRET=<the audio server's auth.jwt_secret> ./scripts/mint-token.sh
```

## Configure

Edit `station.yaml`'s `server.grpc_addr` to point at your audio server
(see [Configuration](configuration.md) for every field). Leave `auth.jwt`
empty in the file — supply the token via the `GORADIO_JWT` environment
variable instead, so a long-lived bearer token never ends up in git
history or a baked image layer.

## Build and run

```sh
docker build -t goradio-gta .

docker run -d \
  -e GORADIO_JWT="$(cat token.txt)" \
  goradio-gta
```

There's no port to publish — this container only dials *out* to
`server.grpc_addr`; nothing inside it listens for inbound traffic
(`api.enabled: false` in `station.yaml`), so no `-p` flag is needed.

## What starts

The entrypoint is `pm2-runtime ecosystem.config.js`, which starts one
`radio station` process per station slug — all eleven GTA:SA stations
plus their `-music` counterparts, all nine GTA III stations, and all nine
Vice City stations, forty processes in one container (see
[Available Stations](../stations/index.md)). PM2 supervises each
independently: one station crash-looping (e.g. because its audio files
are missing) doesn't take any other station down with it.

## Overriding the baked-in config

`station.yaml` is baked into the image as a default/fallback only. For any
real deployment, mount your own over it (a Docker bind mount, or a
Kubernetes ConfigMap — see [Deployment: Kubernetes](../deployment/kubernetes.md))
rather than relying on what's in the image, and supply `auth.jwt` via the
`GORADIO_JWT` environment variable either way — it takes precedence over
whatever the mounted file says.
