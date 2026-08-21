'use strict';

// The eleven GTA San Andreas station slugs station.lua knows about --
// see station.lua's header comment and data/gtasa-stations.json.
const SLUGS = [
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

// Each slug gets two streams: the normal one, and a "-music" one that's
// just back-to-back songs (see station.lua's music_only handling) -- so
// 22 processes total. Both need to be in the JWT's authorized slug list
// (see station.yaml's auth comment) or the "-music" half will sit in a
// registration-error restart loop.
const ALL_SLUGS = SLUGS.flatMap((slug) => [slug, `${slug}-music`]);

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
