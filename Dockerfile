# Runs all eleven GTA:SA `radio station` controllers as one container,
# supervised by PM2 (pm2-runtime, the container-friendly foreground mode).
#
# This container only plays station-controller role -- it dials out to an
# already-running `radio serve` instance (see station.yaml server.grpc_addr)
# rather than running its own server. If you also need to run the audio
# server itself, do that with the base image directly:
# https://tmfksoft.github.io/goradio/deployment/docker/
#
# station.yaml is baked in as a default/fallback only -- deploy it with a
# ConfigMap mounted over /app/station.yaml (and auth.jwt supplied via the
# GORADIO_JWT env var from a Secret, which takes precedence over the file)
# rather than relying on what's baked into the image.
FROM ghcr.io/tmfksoft/goradio:v0.11.1

USER root
RUN apk add --no-cache nodejs npm \
    && npm install -g pm2 \
    && npm cache clean --force

WORKDIR /app
COPY station.lua station.yaml ecosystem.config.js ./
COPY data/adverts.json ./data/adverts.json
COPY data/stations/ ./data/stations/

RUN chown -R radio:radio /app
USER radio

# pm2-runtime replaces the base image's `radio` entrypoint: it stays in the
# foreground, forwards SIGTERM/SIGINT to every managed process for a clean
# shutdown, and streams each station's stdout/stderr to the container's own
# log stream, prefixed by station slug.
ENTRYPOINT ["pm2-runtime", "ecosystem.config.js"]
