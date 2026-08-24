#!/usr/bin/env bash
# Mints a JWT authorizing station slugs against the production audio
# server, using `radio tokengen` from this repo's own base image --
# no local Go build needed.
#
# Usage:
#   GORADIO_JWT_SECRET=<server's auth.jwt_secret> ./scripts/mint-token.sh [-ttl 8760h] [slug...]
#
# With no slugs given, authorizes every station ("*") -- see
# station.yaml's auth comment for why a wildcard beats an explicit list
# now that there are 40+ stations. Prints the token to stdout; paste it
# into k8s/secret.yaml's stringData.jwt (copy from k8s/secret.example.yaml
# first if you haven't -- that template is real-secret-free and safe to
# commit, secret.yaml itself is gitignored).
#
# Examples:
#   GORADIO_JWT_SECRET=... ./scripts/mint-token.sh
#   GORADIO_JWT_SECRET=... ./scripts/mint-token.sh -ttl 24h radio-los-santos wctr
#   GORADIO_JWT_SECRET=... ./scripts/mint-token.sh -ttl 24h 'radio-los-santos*'

set -euo pipefail

if [[ -z "${GORADIO_JWT_SECRET:-}" ]]; then
  echo "error: set GORADIO_JWT_SECRET to the audio server's own auth.jwt_secret" >&2
  exit 1
fi

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Pull the base image tag straight from the Dockerfile so this never
# drifts out of sync as it gets bumped.
image_tag=$(grep -oP '(?<=^FROM ghcr\.io/goradioserver/goradio:)\S+' "$script_dir/../Dockerfile")

ttl="8760h"
if [[ "${1:-}" == "-ttl" ]]; then
  ttl="$2"
  shift 2
fi

slugs=("$@")
if [[ ${#slugs[@]} -eq 0 ]]; then
  slugs=("*")
fi

docker run --rm "ghcr.io/goradioserver/goradio:${image_tag}" \
  tokengen -secret "$GORADIO_JWT_SECRET" -ttl "$ttl" "${slugs[@]}"
