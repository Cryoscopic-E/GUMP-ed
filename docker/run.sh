#! /usr/bin/env bash
# Run a command in the GUMP image. Repo, data and exp dirs are mounted at their host paths,
# so cache metadata (absolute paths) stays valid inside and outside the container.
#   docker/run.sh bash scripts/preprocess/cache_nuplan.sh
#   SPLITS=train,val MAX_EPOCHS=15 docker/run.sh bash scripts/training/train_nuplan.sh
# NUPLAN_DATA_ROOT (default: <repo>/data, symlinks resolved) must contain maps/ and nuplan-v1.1/splits/.
set -e
REPO=$(cd "$(dirname "$0")/.." && pwd)
DATA_DIR=$(readlink -f "${NUPLAN_DATA_ROOT:-$REPO/data}")
EXP_DIR=${NUPLAN_EXP_ROOT:-$REPO/exp}
mkdir -p "$EXP_DIR"

# Forward the script knobs that are set on the host.
ENV_ARGS=()
for v in SPLITS CACHE_NAME EXPERIMENT MODEL MAX_EPOCHS BATCH_SIZE NUM_WORKERS MAX_WORKERS \
         NUM_SCENARIOS_PER_TYPE CKPT_PATH CUDA_VISIBLE_DEVICES; do
    ENV_ARGS+=(-e "$v")
done
[ -t 0 ] && TTY=-it  # interactive only when attached to a terminal (works under nohup)

exec docker run --rm $TTY --gpus "${GPUS:-all}" --ipc=host \
    --user "$(id -u):$(id -g)" \
    -v "$REPO:$REPO" -v "$DATA_DIR:$DATA_DIR:ro" -v "$EXP_DIR:$EXP_DIR" \
    -e NUPLAN_DATA_ROOT="$DATA_DIR" -e NUPLAN_EXP_ROOT="$EXP_DIR" "${ENV_ARGS[@]}" \
    -w "$REPO" "${IMAGE:-gump:latest}" "$@"
