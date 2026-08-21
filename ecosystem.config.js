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

// One `radio station` process per slug -- station.lua serves exactly one
// station per process, so running all eleven means running eleven
// processes (see docs/content/cli/station.md "One process, one station").
// PM2 gives each its own crash isolation and restart policy.
module.exports = {
  apps: SLUGS.map((slug) => ({
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
