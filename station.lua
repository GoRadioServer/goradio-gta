-- station.lua: a GTA III-era radio station (San Andreas, III, Vice City).
--
-- Run it with (from this directory, so the data/ paths below resolve):
--   radio station --config station.yaml --script station.lua <slug>
--
-- <slug> picks which station to play; each run of this script serves
-- exactly one station. Valid slugs are whatever data/stations/index.json
-- lists -- currently the eleven GTA San Andreas stations plus their
-- "-music" (songs-only, see below) counterparts (e.g. radio-los-santos
-- and radio-los-santos-music), plus one station per GTA III and Vice
-- City station (no "-music" counterparts for those -- see below).
--
-- Playback follows the original GTA:SA station format: intro -> song ->
-- outro, then either an advert or a station ident, then maybe a caller
-- or DJ chatter -- reconstructed from https://github.com/tmfksoft/gta-
-- radio's stations/GTASA/*.js data, with audio paths matching this
-- server's data/audio/ layout. GTA III and Vice City stations are
-- modeled the same way but degenerately: each is really one single
-- continuous audio file with the music/ads/DJ chatter already mixed
-- together (that's how the original games shipped them), so each has
-- exactly one "song" and empty intros/outros/idents/callers/chatter --
-- there's no way to split "just the music" back out of one file, hence
-- no "-music" variant for these.
--
-- Each slug's own data (name/game/genre/songs/idents/callers/chatter/...)
-- lives in its own data/stations/<file>.json, found via
-- data/stations/index.json; data/adverts.json is GTA:SA-specific (the
-- only game with separate ad injection) but shared across every GTA:SA
-- station. A "-music" slug is just its own index/data file like any
-- other -- one with play_ads false and empty idents/callers/chatter, and
-- every song's intros/outros stripped to empty too, so the playback
-- cycle below needs no special-casing for it (or for GTA III/Vice City)
-- at all: an empty list is just never picked from.
--
-- Full Lua API docs: https://tmfksoft.github.io/goradio/lua-api/

local json = require("json")

-- Maps each station's "game" field to its data/audio/ subdirectory.
local GAME_AUDIO_DIRS = { gtasa = "GTASA", gta3 = "GTA3", gtavc = "GTAVC" }

local function load_json(path)
  local f, open_err = io.open(path, "r")
  if not f then
    error(string.format("couldn't open %s: %s (run this from the goradio directory)", path, tostring(open_err)))
  end
  local raw = f:read("*a")
  f:close()

  local decoded, decode_err = json.decode(raw)
  if not decoded then
    error(string.format("couldn't parse %s: %s", path, tostring(decode_err)))
  end
  return decoded
end

local ADVERTS = load_json("data/adverts.json")
local INDEX = load_json("data/stations/index.json")

local station_key = radio.args[1] or "radio-los-santos"
local station_file = INDEX[station_key]
if not station_file then
  local keys = {}
  for k in pairs(INDEX) do keys[#keys + 1] = k end
  table.sort(keys)
  error(string.format("unknown station '%s' -- valid slugs: %s", station_key, table.concat(keys, ", ")))
end

local station = load_json("data/stations/" .. station_file)

-- A GTA III/Vice City station has exactly one "song" -- the whole
-- station is one pre-mixed file, tens of minutes long. pick() on a
-- 1-element array always returns that same song, so a threshold of 3
-- would make refill_queue below re-queue *the same giant file* 3-4 times
-- over just to clear the threshold, every single time the queue drains.
-- With every station starting at once, that's dozens of simultaneous
-- transcode jobs for huge files -- exactly what overloaded the audio
-- server in production. A single song has no variety to buffer ahead
-- for anyway, so 0 is correct here: queue exactly one lookahead copy,
-- never a redundant pile of the same file.
local LOW_QUEUE_THRESHOLD = #station.songs > 1 and 3 or 0

local info = radio.register(station_key, station.name, station.genre, {
  low_queue_threshold = LOW_QUEUE_THRESHOLD,
  logo_url = station.logo_url,
  metadata = { game = station.game, type = station.type },
})
print(string.format("registered '%s' -> %s (%s, DJ %s)", info.slug, info.stream_url, station.name, station.dj_name))

math.randomseed(os.time())

local function pick(arr)
  return arr[math.random(#arr)]
end

local function track(filename)
  return GAME_AUDIO_DIRS[station.game] .. "/" .. station.audio_dir .. "/" .. filename
end

-- Mirrors gta-radio's original playback cycle: intro -> song -> outro, then
-- either an advert or a station ident, then maybe a caller or DJ chatter.
-- Every "if #list > 0" here is what makes a "-music" station's empty
-- idents/callers/chatter (and each song's empty intros/outros) result in
-- just the song itself, with no separate code path needed.
local function queue_song_cycle()
  local song = pick(station.songs)

  if #song.intros > 0 then
    radio.queue(track(pick(song.intros)))
  end

  radio.queue({ location = track(song.middle), title = song.name, artist = song.artist })

  if #song.outros > 0 then
    radio.queue(track(pick(song.outros)))
  end

  local roll = math.random(0, 99)

  if roll <= 70 and station.play_ads and #ADVERTS > 0 then
    local advert = pick(ADVERTS)
    radio.queue({ location = GAME_AUDIO_DIRS.gtasa .. "/Adverts/" .. advert.file, title = advert.name, artist = "Advertisement" })
  elseif #station.idents > 0 then
    radio.queue(track(pick(station.idents)))
  end

  if roll <= 10 and #station.callers > 0 then
    radio.queue(track(pick(station.callers)))
  elseif roll <= 50 and #station.chatter > 0 then
    radio.queue(track(pick(station.chatter)))
  end
end

radio.on_track_started(function(t)
  if t.title ~= "" then
    print(string.format("now playing: %s - %s", t.artist, t.title))
  end
end)

radio.on_error(function(err)
  print(string.format("error: %s (%s)", err.message, err.code))
end)

-- The audio server's QUEUE_LOW event is edge-triggered: it only fires
-- again once the queue has climbed back *above* low_queue_threshold and
-- then dropped to it again. A single queue_song_cycle() call can add as
-- few as one item -- always true for a "-music" station, and possible
-- for a regular one too (e.g. sf-ur has no idents to fall back on when
-- its ~30% no-advert roll comes up) -- which is never enough to climb
-- back above a threshold of 3. Left as a single call, that under-fill
-- doesn't just risk one thin refill: it leaves the queue permanently
-- stuck at or below the threshold, so the edge never re-arms and
-- on_queue_low silently stops firing for the rest of the process.
-- refill_queue loops until the queue is actually healthy again, checking
-- first so it's a no-op when called from on_register (below) and the
-- queue turns out to still be fine -- e.g. a brief network blip that
-- didn't actually restart the audio server. The iteration cap is just a
-- safety net against spinning forever if everything this station tries
-- to queue fails outright (e.g. a broken audio_root).
local function refill_queue()
  if radio.status().queue_length > LOW_QUEUE_THRESHOLD then
    return
  end
  for _ = 1, 20 do
    queue_song_cycle()
    if radio.status().queue_length > LOW_QUEUE_THRESHOLD then
      return
    end
  end
end

radio.on_queue_low(refill_queue)

-- If the audio server itself restarted while we were disconnected, its
-- registry -- and this station's entire queue -- comes back empty when
-- the engine auto-reconnects and re-registers us, and on_queue_low alone
-- can't rescue that (its edge trigger never fires for a queue that's
-- been empty since the moment it was recreated). Re-priming here as well
-- as at the bottom of the script covers both cases: this fires the queue
-- back up after a reconnect-driven restart, that fires it once at the
-- very first startup.
radio.on_register(refill_queue)

refill_queue()
