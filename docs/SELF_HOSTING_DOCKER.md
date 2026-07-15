# Self-hosting openDAW with Docker

This fork adds a reproducible, multi-stage container build for the openDAW Studio web application. The build stage compiles the TypeScript and Rust/WASM workspace; the runtime stage serves only the generated static files through unprivileged-by-configuration Nginx on port 8080.

## Requirements

- Docker Engine 24 or newer with Docker Compose v2
- An amd64 or arm64 Linux host with at least 4 GB RAM available during the build
- Internet access while building the image

No runtime secrets or persistent volumes are required. Browser projects remain in browser-managed storage, so users should export important work separately.

## Build and run

```bash
docker compose build
docker compose up -d
docker compose ps
curl --fail http://127.0.0.1:8080/healthz
```

The conservative default binds only to `127.0.0.1:8080`. To expose it directly on a trusted LAN:

```bash
OPENDAW_BIND=0.0.0.0 OPENDAW_PORT=8080 docker compose up -d
```

For internet access, keep the loopback binding and place the service behind an HTTPS reverse proxy. Audio worklets require the cross-origin isolation headers already provided by `docker/nginx.conf`.

## Update and rollback

Before updating, record the current image ID:

```bash
docker image inspect opendaw-selfhosted:local --format '{{.Id}}'
git pull --ff-only
docker compose build --pull
docker compose up -d
```

If the new image fails its health check, retag the recorded image ID as `opendaw-selfhosted:local` and run `docker compose up -d` again.

## Verification

```bash
docker compose ps
docker inspect --format '{{json .State.Health}}' "$(docker compose ps -q opendaw)"
curl --fail --head http://127.0.0.1:8080/
curl --fail http://127.0.0.1:8080/healthz
```

The GitHub Actions workflow also builds the image when container-related files change. It validates build reproducibility without publishing an image or requiring registry credentials.
