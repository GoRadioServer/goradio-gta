# Prerequisites

Before running this image, you need three things:

## 1. A running GoRadio audio server

This image only runs station *controllers* — it never runs `radio serve`
itself. Have one reachable already, following GoRadio's own
[Quickstart](https://goradioserver.github.io/goradio/getting-started/quickstart/)
if you don't. Note its gRPC address; you'll put that in `station.yaml`.

## 2. A JWT authorizing every station slug

Every station this image runs needs to be an authorized slug on the token
it presents. With 40+ stations (see
[Available Stations](../stations/index.md)) and growing, a wildcard token
is far more maintainable than listing each slug out — mint one with
[`scripts/mint-token.sh`](https://github.com/GoRadioServer/goradio-gta/blob/main/scripts/mint-token.sh):

```sh
GORADIO_JWT_SECRET=<the audio server's auth.jwt_secret> ./scripts/mint-token.sh
```

This runs `radio tokengen` from the image itself (no local Go install
needed), reading the base image tag straight out of the `Dockerfile` so it
never drifts out of sync. With no slugs given it authorizes every station
(`*`) — see [Running with Docker](running.md) for where the result goes.

## 3. Your own GTA audio files

This repo ships the *data* describing how each station plays — song
names, artists, DJ lines, playback structure — not the audio itself, which
is the games' own copyrighted assets. You need a legally-obtained copy of
GTA III, Vice City, and/or San Andreas to extract `.ogg` files from,
matching the directory layout [Running with Docker](running.md#audio-layout)
describes. A missing file isn't a hard failure — the audio server skips
that one queue item, logs it, and fires an error event, then moves on to
whatever's queued next (see
[Troubleshooting](../troubleshooting.md#a-station-only-ever-plays-silence)) —
but a station is only as complete as the audio you've actually supplied
for it, and if *everything* it tries to queue fails, the queue drains
empty and it falls back to looping silence like any other station with
nothing left to play.
