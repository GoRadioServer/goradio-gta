# Available Stations

Forty station processes across three games — the slug is what you pass to
`radio station ... <slug>` (or what `ecosystem.config.js` already passes
for you when running the full container). Every San Andreas station has a
`-music` counterpart: the same station with ads, idents, callers, and DJ
chatter stripped out, back-to-back songs only. GTA III and Vice City
stations have no `-music` counterpart — each is one continuous pre-mixed
file, the same way the original games shipped them, so there's no
separate music track to split back out.

## GTA San Andreas

| Slug | Station | Slug (music-only) |
|---|---|---|
| `radio-los-santos` | Radio Los Santos | `radio-los-santos-music` |
| `playback-fm` | Playback FM | `playback-fm-music` |
| `bounce-fm` | Bounce FM | `bounce-fm-music` |
| `sf-ur` | SF-UR | `sf-ur-music` |
| `radio-x` | Radio X | `radio-x-music` |
| `csr` | CSR 103.9 | `csr-music` |
| `k-dst` | K-DST | `k-dst-music` |
| `k-jah-west` | K-JAH West | `k-jah-west-music` |
| `k-rose` | K-Rose | `k-rose-music` |
| `master-sounds` | Master Sounds 98.3 | `master-sounds-music` |
| `wctr` | West Coast Talk Radio | `wctr-music` |

## GTA III

| Slug | Station |
|---|---|
| `chatterbox-fm` | Chatterbox FM |
| `double-clef-fm` | Double Clef FM |
| `flashback-fm` | Flashback FM |
| `game-radio` | Game Radio |
| `head-radio` | Head Radio |
| `k-jah` | K-JAH |
| `lips` | Lips 106 |
| `msx-fm` | MSX FM |
| `rise-fm` | Rise FM |

## GTA Vice City

| Slug | Station |
|---|---|
| `emotion` | Emotion 98.3 |
| `fever-105` | Fever 105 |
| `flash-fm` | Flash FM |
| `k-chat` | K-Chat |
| `radio-espantoso` | Radio Espantoso |
| `v-rock` | V-Rock |
| `vcpr` | Vice City Public Radio |
| `wave-103` | Wave 103 |
| `wildstyle` | Wildstyle |

Each slug maps to a `data/stations/<slug>.json` file, found via
`data/stations/index.json` — see
[Station Data Format](data-format.md) for what's in one and how to add a
new station.
