#! /usr/bin/env bash
# Cache nuPlan features for GUMP v1.1. Run from repo root, on the host (uv) or via docker/run.sh.
#   bash scripts/preprocess/cache_nuplan.sh                                       # mini split, smoke test
#   SPLITS=train,val NUM_SCENARIOS_PER_TYPE=null bash scripts/preprocess/cache_nuplan.sh
# Expects $NUPLAN_DATA_ROOT/nuplan-v1.1/splits/<split>/*.db and $NUPLAN_MAPS_ROOT.
set -e
SPLITS=${SPLITS:-mini}
CACHE_NAME=${CACHE_NAME:-cache_${SPLITS//,/_}}

export NUPLAN_DATA_ROOT=${NUPLAN_DATA_ROOT:-$PWD/data}
export NUPLAN_MAPS_ROOT=${NUPLAN_MAPS_ROOT:-$NUPLAN_DATA_ROOT/maps}
export NUPLAN_EXP_ROOT=${NUPLAN_EXP_ROOT:-$PWD/exp}
DATA_ROOT="[$(echo "$SPLITS" | sed "s|[^,]*|$NUPLAN_DATA_ROOT/nuplan-v1.1/splits/&|g")]"

export PYTHONPATH=$PWD:$PYTHONPATH
export OPENBLAS_NUM_THREADS=1 # This is to avoid OpenBlas creating too many threads
export OMP_NUM_THREADS=1  # Control the number of threads per process for OpenMP

uv run python -W ignore nuplan_extent/planning/script/run_training.py \
    group=$NUPLAN_EXP_ROOT/save_dir \
    cache.cache_path=$NUPLAN_EXP_ROOT/$CACHE_NAME \
    cache.force_feature_computation=true \
    cache.versatile_caching=false \
    experiment_name=caching_$CACHE_NAME \
    job_name=caching \
    py_func=cache \
    +training=training_nuplan_gump_v1_1 \
    scenario_builder=nuplan \
    scenario_filter=all_scenarios \
    scenario_builder.scenario_mapping.subsample_ratio_override=1 \
    worker=single_machine_thread_pool \
    worker.use_process_pool=true \
    worker.max_workers=${MAX_WORKERS:-16} \
    model=${MODEL:-gump_nuplan_llama_sm_v1_1} \
    scenario_builder.data_root=$DATA_ROOT \
    scenario_builder.map_root=$NUPLAN_MAPS_ROOT \
    scenario_filter.timestamp_threshold_s=15 \
    scenario_filter.num_scenarios_per_type=${NUM_SCENARIOS_PER_TYPE:-10} \
    scenario_filter.expand_scenarios=false \
    scenario_filter.remove_invalid_goals=true \
    "$@"
