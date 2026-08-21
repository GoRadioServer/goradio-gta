-- station.lua: a GTA:SA-style radio station.
--
-- Run it with (from this directory, so the data/ path below resolves):
--   radio station --config station.yaml --script station.lua <slug>
--
-- <slug> picks which of the eleven GTA San Andreas stations to play; each
-- run of this script serves exactly one station. Valid slugs:
--   radio-los-santos, playback-fm, bounce-fm, sf-ur, radio-x, csr, k-dst,
--   k-jah-west, k-rose, master-sounds, wctr
--
-- Append "-music" to any of those (e.g. radio-los-santos-music) to
-- register a second stream for the same station that plays nothing but
-- back-to-back songs -- no intros/outros, idents, adverts, callers, or DJ
-- chatter.
--
-- Playback follows the original station format: intro -> song -> outro,
-- then either an advert or a station ident, then maybe a caller or DJ
-- chatter -- reconstructed from https://github.com/tmfksoft/gta-radio's
-- stations/GTASA/*.js data, with audio paths matching this server's
-- data/audio/ layout. The station/song/advert data itself lives in
-- data/gtasa-stations.json, loaded below.
--
-- Full Lua API docs: https://tmfksoft.github.io/goradio/lua-api/

local json = require("json")

local DATA_PATH = "data/gtasa-stations.json"

local f, open_err = io.open(DATA_PATH, "r")
if not f then
  error(string.format("couldn't open %s: %s (run this from the goradio directory)", DATA_PATH, tostring(open_err)))
end
local raw = f:read("*a")
f:close()

local data, decode_err = json.decode(raw)
if not data then
  error(string.format("couldn't parse %s: %s", DATA_PATH, tostring(decode_err)))
end

local STATIONS = data.stations
local ADVERTS = data.adverts

local station_key = radio.args[1] or "radio-los-santos"

-- A "-music" suffix requests a music-only stream for the same underlying
-- station -- strip it to find the station data, but keep the full,
-- suffixed key as the registered slug.
local music_only_base = station_key:match("^(.*)%-music$")
local music_only = music_only_base ~= nil
local station = STATIONS[music_only and music_only_base or station_key]
if not station then
  local keys = {}
  for k in pairs(STATIONS) do
    keys[#keys + 1] = k
    keys[#keys + 1] = k .. "-music"
  end
  table.sort(keys)
  error(string.format("unknown station '%s' -- valid slugs: %s", station_key, table.concat(keys, ", ")))
end

local display_name = music_only and (station.name .. " (Music Only)") or station.name
local info = radio.register(station_key, display_name, station.genre,
  { low_queue_threshold = 3, logo_url = station.logo_url })
print(string.format("registered '%s' -> %s (%s, DJ %s)", info.slug, info.stream_url, display_name, station.dj_name))

math.randomseed(os.time())

local function pick(arr)
  return arr[math.random(#arr)]
end

local function track(filename)
  return  "GTASA/" .. station.audio_dir .. "/" .. filename
end

-- Mirrors gta-radio's original playback cycle: intro -> song -> outro, then
-- either an advert or a station ident, then maybe a caller or DJ chatter.
-- The "-music" variant (see music_only above) skips straight to just the
-- song itself, forever.
local function queue_song_cycle()
  local song = pick(station.songs)

  if music_only then
    radio.queue({ location = track(song.middle), title = song.name, artist = song.artist })
    return
  end

  if #song.intros > 0 then
    radio.queue(track(pick(song.intros)))
  end

  radio.queue({ location = track(song.middle), title = song.name, artist = song.artist })

  if #song.outros > 0 then
    radio.queue(track(pick(song.outros)))
  end

  local roll = math.random(0, 99)

  if roll <= 70 and station.play_ads and #ADVERTS > 0 then
    radio.queue("GTASA/Adverts/" .. pick(ADVERTS))
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

-- Keeps the queue topped up: refill whenever it drops to the threshold set
-- in radio.register above.
radio.on_queue_low(function()
  queue_song_cycle()
end)

-- Prime a couple of cycles up front so there's a buffer before the first
-- on_queue_low callback.
queue_song_cycle()
queue_song_cycle()
