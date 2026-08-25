# goradio-gta

Turnkey GTA III, Vice City, and San Andreas radio stations, reconstructed
as real [GoRadio](https://github.com/GoRadioServer/goradio) station
controllers — forty-odd stations, each one a `radio station` process
running the original intro → song → outro → advert/ident → caller/chatter
playback cycle the games themselves used.

**📖 [Full documentation](https://goradioserver.github.io/goradio-gta/)** —
prerequisites, running with Docker, the station data format, and
Kubernetes deployment.

This is a **station-controller** image, not an audio server — it dials
out to an already-running `radio serve` instance rather than running one
itself. And it ships the station *data* (names, DJ lines, playback
structure), not the audio: GTA's music and voice lines are the games' own
copyrighted assets, so you need your own legally-obtained copy of the
game(s) to extract `.ogg` files from.

```sh
git clone https://github.com/GoRadioServer/goradio-gta
cd goradio-gta
# lay your own extracted audio out under data/audio/ -- see the docs
GORADIO_JWT_SECRET=<your audio server's auth.jwt_secret> ./scripts/mint-token.sh
docker build -t goradio-gta .
docker run -d -e GORADIO_JWT="$(cat token.txt)" goradio-gta
```

See the [docs](https://goradioserver.github.io/goradio-gta/) for the exact
audio directory layout, `station.yaml` reference, the full station list,
and troubleshooting.

## License

MIT — see [`LICENSE`](LICENSE).
