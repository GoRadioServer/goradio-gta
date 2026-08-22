'use strict';

// The eleven GTA San Andreas station slugs station.lua knows about --
// see station.lua's header comment and data/stations/index.json. Each
// gets two streams: the normal one, and a "-music" one that's just
// back-to-back songs -- so 22 processes for these alone. Both halves
// need to be in the JWT's authorized slug list (see station.yaml's auth
// comment) or the "-music" half will sit in a registration-error restart
// loop.
const GTASA_SLUGS = [
  'radio-los-santos',
  'playback-fm',
  'bounce-fm',
  'sf-ur',
  'radio-x',
  'csr',
  'k-dst',
  'k-jah-west',
  'k-rose',
  'master-sounds',
  'wctr',
];

// GTA III and Vice City stations: one single continuous audio file each
// (music/ads/DJ chatter already mixed together, same as the original
// games shipped them) -- no "-music" counterpart is possible for these.
const GTA3_SLUGS = [
  'chatterbox-fm',
  'double-clef-fm',
  'flashback-fm',
  'game-radio',
  'head-radio',
  'k-jah',
  'lips',
  'msx-fm',
  'rise-fm',
];

const GTAVC_SLUGS = [
  'emotion',
  'fever-105',
  'flash-fm',
  'k-chat',
  'radio-espantoso',
  'v-rock',
  'vcpr',
  'wave-103',
  'wildstyle',
];

const ALL_SLUGS = [
  ...GTASA_SLUGS.flatMap((slug) => [slug, `${slug}-music`]),
  ...GTA3_SLUGS,
  ...GTAVC_SLUGS,
];

// One `radio station` process per slug -- station.lua serves exactly one
// station per process, so running all of them means running all of them
// as separate processes (see docs/content/cli/station.md "One process,
// one station"). PM2 gives each its own crash isolation and restart policy.
module.exports = {
  apps: ALL_SLUGS.map((slug) => ({
    name: slug,
    script: '/usr/local/bin/radio',
    interpreter: 'none',
    args: `station --config station.yaml --script station.lua ${slug}`,
    cwd: '/app',
    autorestart: true,
    restart_delay: 5000,
    max_restarts: 50,
  })),
};
