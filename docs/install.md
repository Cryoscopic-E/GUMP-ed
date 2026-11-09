# Installation

Two environments share one dependency spec (`pyproject.toml` + `uv.lock`):

- **dev machine**: plain `uv` virtualenv, for editing and quick runs.
- **GPU server**: Docker image with the same dependencies; the repo checkout is mounted, not baked in.

`third_party/nuplan-devkit` (branch `feat-v1.3_gump`) and `third_party/alf` are git submodules pinned to exact commits.

## Clone

```bash
git clone --recursive <this repo>
# already cloned: git submodule update --init
ln -s /path/to/nuplan data   # must contain maps/ and nuplan-v1.1/splits/{mini,train,val,...}
```

## Dev machine (uv)

```bash
sudo apt install -y libboost-dev   # needed to build ALF's C++ extension
uv sync                            # python 3.9, torch 2.3.0+cu121
```

Smoke test on the mini split (outputs in `exp/`):

```bash
bash scripts/preprocess/cache_nuplan.sh
bash scripts/training/train_nuplan.sh
```

## GPU server (Docker)

Requires Docker with nvidia-container-toolkit (`docker run --gpus all ...` works) and an NVIDIA driver >= 530.

```bash
git pull && git submodule update --init
docker build -f docker/Dockerfile -t gump .   # only needed when pyproject.toml / uv.lock / third_party change
docker/run.sh bash scripts/preprocess/cache_nuplan.sh   # mini smoke test
docker/run.sh bash scripts/training/train_nuplan.sh
```

`docker/run.sh` mounts the repo, the data dir (`$NUPLAN_DATA_ROOT`, default `./data` with symlinks resolved) and the
output dir (`$NUPLAN_EXP_ROOT`, default `./exp`) at their host paths, and runs as your user so outputs are not root-owned.

Full training (detached, survives logout):

```bash
SPLITS=train,val NUM_SCENARIOS_PER_TYPE=null MAX_WORKERS=32 \
    nohup docker/run.sh bash scripts/preprocess/cache_nuplan.sh > exp/cache_train_val.log 2>&1 &
SPLITS=train,val MAX_EPOCHS=15 \
    nohup docker/run.sh bash scripts/training/train_nuplan.sh > exp/train_train_val.log 2>&1 &
tensorboard --logdir exp/save_dir
```

## Script knobs

Both scripts read these environment variables (forwarded into the container by `docker/run.sh`). Extra arguments are passed
to hydra, e.g. `bash scripts/training/train_nuplan.sh lightning.trainer.params.limit_val_batches=2`.

| Variable | Default | Meaning |
|---|---|---|
| `SPLITS` | `mini` | comma-separated dirs under `nuplan-v1.1/splits/` |
| `CACHE_NAME` | `cache_<splits>` | cache dir under `$NUPLAN_EXP_ROOT` |
| `NUM_SCENARIOS_PER_TYPE` | `10` | caching filter; `null` = all scenarios |
| `MAX_WORKERS` | `16` | caching processes |
| `MODEL` | `gump_nuplan_llama_sm_v1_1` | model config |
| `EXPERIMENT` | `train_<splits>` | experiment name under `exp/save_dir` |
| `MAX_EPOCHS` / `BATCH_SIZE` / `NUM_WORKERS` | `2` / `4` / `8` | training |
| `CKPT_PATH` | `null` | checkpoint to initialise from |

Cache metadata stores absolute paths, so a cache made on one machine is only valid where the same paths exist.
