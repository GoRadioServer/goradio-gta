# Configuration

## `station.yaml`

Default filename `station.yaml`, overridden with
`radio station --config <path>`. Pairs with a Lua script (`station.lua`
here, default filename), overridden with `--script <path>`. Any trailing
CLI args after these flags pass through to the script unparsed — that's
how one shared `station.lua` serves any of the forty station slugs
(`ecosystem.config.js` passes the slug as that trailing arg per process).

```yaml
server:
  grpc_addr: "https://radio-rpc.tbt.services"

auth:
  jwt: ""

station:
  slug: "radio-los-santos"

api:
  enabled: false
  bind_host: "127.0.0.1:8091"
  api_key: "CHANGE_ME"

logging:
  level: "info"
```

- `server.grpc_addr` — your audio server's gRPC control plane.
- `auth.jwt` — left empty deliberately (see
  [Prerequisites](prerequisites.md#2-a-jwt-authorizing-every-station-slug)).
  Supply it via the `GORADIO_JWT` environment variable instead, which
  always takes precedence over this file's value.
- `station.slug` — which station this process serves. `ecosystem.config.js`
  overrides this per process via a trailing CLI arg, so this value is only
  what you get running `station.lua` directly without one.
- `api.enabled` — this image never needs an inbound API; leave it `false`
  unless you know you need it.

## Environment variables

| Variable | Overrides |
|---|---|
| `GORADIO_JWT` | `auth.jwt` |

That's the only one this image relies on. Everything else — which audio
server to dial, which station slug, logging level — comes from
`station.yaml` (or a mounted replacement; see
[Running with Docker](running.md#overriding-the-baked-in-config)).
