# Troubleshooting

## Checking one station's logs

PM2 runs all forty stations as separate processes in one container, named
after their slug (see `ecosystem.config.js`). To see just one:

```sh
docker exec -it <container> pm2 logs k-rose
```

or, without `pm2` inside the container, `docker logs <container>` and
grep for the slug — every log line `station.lua` prints is unprefixed by
station, but PM2's own foreground output tags each line with its process
name.

## A "-music" station is stuck restarting

Every San Andreas station registers two slugs — `<slug>` and
`<slug>-music` — and **both** need to be in the JWT's authorized slug
list. A token minted for only the base slugs (rather than a wildcard `*`,
or explicitly including every `-music` variant) leaves each `-music`
process failing to register, over and over, in a restart loop — PM2 keeps
retrying (`autorestart: true`, `max_restarts: 50`) rather than giving up
visibly. Re-mint with `./scripts/mint-token.sh` and no slug arguments to
get a wildcard token that covers everything, or explicitly list every
`-music` slug alongside its base station if you're intentionally scoping
the token down.

## A station only ever plays silence

In order of likelihood:

1. **Its audio files aren't where `station.lua` expects them.** Check
   `data/audio/<GAME>/<audio_dir>/` matches the station's actual `game`
   and `audio_dir` fields (see
   [Station Data Format](stations/data-format.md)) — `audio_dir` is a real
   directory name, not always the same as the slug. A missing/mismatched
   file makes that one queue item fail to prefetch (logged, and reported
   via an error event) rather than crash the process — with everything it
   tries to queue failing the same way, the queue never has anything
   playable in it and the station falls back to looping silence, same as
   any station with an empty queue.
2. **The token doesn't authorize this slug.** See the `-music` restart
   loop above — the same failure mode applies to any slug missing from
   the token, not just `-music` ones.
3. **`server.grpc_addr` is unreachable or wrong.** Check the container's
   logs for a connection error rather than a registration error — those
   are different failures with the same symptom from the outside.

## Every station is unreachable / nothing registers

Check `server.grpc_addr` in `station.yaml` (or the mounted ConfigMap, in
Kubernetes) actually resolves and accepts connections from where this
container runs — a value that works from your laptop isn't necessarily
reachable from inside a cluster or a different Docker network.

## Rebuilding after changing station data

Station data (`data/stations/*.json`, `data/adverts.json`) and
`station.lua` itself are baked into the image at build time (see the
`Dockerfile`'s `COPY` lines) — a change to either needs a rebuild
(`docker build -t goradio-gta .`) and a fresh container, not just a
restart of the existing one.
