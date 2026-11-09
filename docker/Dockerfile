# GUMP training image: dependencies only. The repo is mounted at run time (see docker/run.sh),
# so code changes need only a `git pull`; rebuild when pyproject.toml, uv.lock or third_party/ change.
# Build from repo root (submodules checked out):  docker build -f docker/Dockerfile -t gump .
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
# build-essential: triton JIT + alf C++ extension; libboost-dev: alf; libgl1/libglib2.0-0: opencv
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential ca-certificates git libboost-dev libgl1 libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=ghcr.io/astral-sh/uv:0.11.16 /uv /uvx /usr/local/bin/

# Python and venv live outside /root so a non-root `--user` can use them.
ENV UV_PYTHON_INSTALL_DIR=/opt/uv-python \
    UV_PROJECT_ENVIRONMENT=/opt/gump/.venv \
    UV_LINK_MODE=copy \
    UV_COMPILE_BYTECODE=1

# third_party is copied (not mounted): alf builds its .so in-tree and nuplan-devkit is installed editable from here.
WORKDIR /opt/gump
COPY pyproject.toml uv.lock ./
COPY third_party/nuplan-devkit third_party/nuplan-devkit
COPY third_party/alf third_party/alf
RUN --mount=type=cache,target=/root/.cache/uv uv sync --frozen

# At run time `uv run` (used by the scripts) reuses /opt/gump/.venv from the mounted repo without re-syncing.
ENV UV_NO_SYNC=1 \
    UV_FROZEN=1 \
    PATH=/opt/gump/.venv/bin:$PATH \
    HOME=/tmp \
    NUMBA_CACHE_DIR=/tmp/numba_cache
