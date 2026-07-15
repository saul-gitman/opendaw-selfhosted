# syntax=docker/dockerfile:1

FROM node:24-bookworm-slim AS build

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        binaryen \
        build-essential \
        ca-certificates \
        curl \
        pkg-config \
        xz-utils && \
    rm -rf /var/lib/apt/lists/*

RUN curl --proto '=https' --tlsv1.2 --fail --silent --show-error \
        https://sh.rustup.rs | sh -s -- -y --profile minimal && \
    . "$HOME/.cargo/env" && \
    rustup target add wasm32-unknown-unknown && \
    rustup toolchain install nightly --profile minimal && \
    rustup +nightly target add wasm32-unknown-unknown && \
    rustup +nightly component add rust-src

WORKDIR /app

COPY package.json package-lock.json turbo.json lerna.json ./
COPY packages ./packages
COPY scripts ./scripts
COPY crates ./crates

RUN npm ci

ENV PATH="/root/.cargo/bin:${PATH}" \
    NODE_ENV=production \
    CI=false \
    BRANCH_NAME=main

RUN npm run build -- --filter=@opendaw/app-studio

FROM nginx:1.27-alpine AS runtime

COPY docker/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/packages/app/studio/dist /usr/share/nginx/html

EXPOSE 8080

USER nginx

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD wget -qO- http://127.0.0.1:8080/healthz >/dev/null || exit 1
