# goradio-gta

Turnkey GTA III, Vice City, and San Andreas radio stations, reconstructed
as real [GoRadio](https://goradioserver.github.io/goradio/) station
controllers — forty-odd stations, each one a `radio station` process
running the original intro → song → outro → advert/ident → caller/chatter
playback cycle the games themselves used, driven from data rather than
hand-written per-station scripts.

This is a **station-controller** image, not an audio server. It dials out
to an already-running `radio serve` instance (see
[Configuration](getting-started/configuration.md)) — if you don't have one
yet, start with GoRadio's own
[Quickstart](https://goradioserver.github.io/goradio/getting-started/quickstart/).

## What's in the container

One Lua script, [`station.lua`](https://github.com/GoRadioServer/goradio-gta/blob/main/station.lua),
serves exactly one station per process — it reads that station's
`data/stations/<slug>.json` (name, DJ, songs, idents, callers, chatter,
ad eligibility) and reconstructs the original playback cycle from it.
[PM2](https://pm2.keymetrics.io/) runs one such process per station, all
in one container, supervising restarts independently per station — see
[Available Stations](stations/index.md) for the full list.

## What you have to supply

**The station *data* (names, DJ lines, song lists, playback structure) is
in this repo. The actual audio is not** — GTA's music and voice lines are
the games' own copyrighted assets, so this repo ships the JSON describing
how each station plays, not the `.ogg` files it references. You need your
own legally-obtained copy of the relevant game(s) to extract audio from,
laid out to match what `station.lua` expects. See
[Running with Docker](getting-started/running.md) for the exact directory
layout.

## Where to start

- [Prerequisites](getting-started/prerequisites.md) — what you need before
  running this.
- [Running with Docker](getting-started/running.md) — the container,
  the audio layout, and minting a token.
- [Configuration](getting-started/configuration.md) — `station.yaml` and
  environment variables.
- [Available Stations](stations/index.md) — every slug this image knows,
  by game.
- [Deployment: Kubernetes](deployment/kubernetes.md).
- [Troubleshooting](troubleshooting.md).
