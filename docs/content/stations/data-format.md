# Station Data Format

Each slug in `data/stations/index.json` maps to its own
`data/stations/<file>.json` — one file per station, holding everything
`station.lua` needs to reconstruct its playback cycle.

## `index.json`

A flat slug → filename map:

```json
{
  "k-rose": "k-rose.json",
  "k-rose-music": "k-rose-music.json"
}
```

## A station file

```json
{
  "name": "K-Rose",
  "game": "gtasa",
  "genre": "Country",
  "dj_name": "Mary-Beth Maybell",
  "audio_dir": "KROSE",
  "play_ads": true,
  "logo_url": "https://gta-tiles.upl.im/radio/logo/SA/K-Rose-GTASA-Logo.svg",
  "type": "regular",
  "songs": [
    {
      "name": "All My Exes Live in Texas",
      "artist": "George Strait",
      "intros": ["All My Exes Live in Texas (Intro DJ #1).ogg", "..."],
      "middle": "All My Exes Live in Texas (Mid).ogg",
      "outros": ["All My Exes Live in Texas (Outro DJ #1).ogg", "..."]
    }
  ],
  "idents": ["..."],
  "callers": ["..."],
  "chatter": ["..."]
}
```

- `game` — `gtasa`, `gta3`, or `gtavc`. Picks which top-level folder under
  `data/audio/` this station's files live in (`GTASA`/`GTA3`/`GTAVC`).
- `audio_dir` — the real directory name under that folder, not
  necessarily the slug — see [Running with Docker](../getting-started/running.md#audio-layout).
- `play_ads` — whether `station.lua`'s playback cycle ever rolls an
  advert for this station. `false` for every `-music` variant and for
  GTA III/Vice City stations (only San Antonio-era GTA:SA has separate ad
  injection).
- `type` — `"regular"` or `"music-only"`, purely descriptive; nothing in
  `station.lua` branches on it directly (an empty `idents`/`callers`/
  `chatter` array already produces the same effect, see below).
- `songs[].intros`/`.outros` — arrays; one is picked at random per play, or
  the song plays with no intro/outro if the array is empty.
- `songs[].middle` — the one required file per song: the song itself,
  intro and outro excluded.
- `idents`/`callers`/`chatter` — arrays of filenames played between songs
  (a station ident, a caller segment, or DJ chatter), each optional.

An empty array anywhere in this file is not a special case `station.lua`
has to detect — `pick()` on an empty list is simply never called, so a
`-music` station (empty `idents`/`callers`/`chatter`, and every song's
`intros`/`outros` stripped to `[]`) or a GTA III/Vice City station
(`songs` has exactly one entry, one continuous pre-mixed file) fall out of
the same code path as a full station, just with fewer branches taken.

## Adding a station

1. Add an entry to `data/stations/index.json`.
2. Write `data/stations/<your-slug>.json` following the shape above.
3. Lay the matching `.ogg` files out under `data/audio/<GAME>/<audio_dir>/`
   (see [Running with Docker](../getting-started/running.md#audio-layout)).
4. Add the slug to `ecosystem.config.js`'s `GTASA_SLUGS`/`GTA3_SLUGS`/
   `GTAVC_SLUGS` array (San Andreas stations also need the `-music`
   counterpart added if you're creating one) so PM2 actually starts a
   process for it.
5. If it's authorized by a wildcard token (`*`), no token changes are
   needed — see [Prerequisites](../getting-started/prerequisites.md#2-a-jwt-authorizing-every-station-slug).
