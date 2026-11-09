#! /usr/bin/env bash
# Train GUMP v1.1 on a cache made by scripts/preprocess/cache_nuplan.sh. Run from repo root, on the host or via docker/run.sh.
#   bash scripts/training/train_nuplan.sh                                         # 2-epoch smoke test on mini
#   SPLITS=train,val MAX_EPOCHS=15 bash scripts/training/train_nuplan.sh
# Extra args are passed to hydra, e.g. `lightning.trainer.params.max_time=00:12:00:00`.
set -e
SPLITS=${SPLITS:-mini}
CACHE_NAME=${CACHE_NAME:-cache_${SPLITS//,/_}}
EXPERIMENT=${EXPERIMENT:-train_${SPLITS//,/_}}

export NUPLAN_DATA_ROOT=${NUPLAN_DATA_ROOT:-$PWD/data}
export NUPLAN_MAPS_ROOT=${NUPLAN_MAPS_ROOT:-$NUPLAN_DATA_ROOT/maps}
export NUPLAN_EXP_ROOT=${NUPLAN_EXP_ROOT:-$PWD/exp}
CACHE_DIR=$NUPLAN_EXP_ROOT/$CACHE_NAME
export CUDA_VISIBLE_DEVICES=${CUDA_VISIBLE_DEVICES:-0}
export PYTHONPATH=$PWD:$PYTHONPATH

uv run python -W ignore nuplan_extent/planning/script/run_training.py \
    group=$NUPLAN_EXP_ROOT/save_dir \
    cache.cache_path=$CACHE_DIR \
    cache.cache_metadata_path=$CACHE_DIR/metadata/${CACHE_NAME}_metadata_node_0.csv \
    cache.force_feature_computation=false \
    cache.use_cache_without_dataset=true \
    cache.versatile_caching=false \
    experiment_name=$EXPERIMENT \
    py_func=train \
    seed=0 \
    +training=training_nuplan_gump_v1_1 \
    scenario_builder=nuplan \
    scenario_builder.scenario_mapping.subsample_ratio_override=1 \
    lightning.trainer.params.accelerator=gpu \
    lightning.trainer.params.max_epochs=${MAX_EPOCHS:-2} \
    lightning.trainer.params.precision=16 \
    lightning.trainer.params.gradient_clip_val=5.0 \
    lightning.trainer.params.strategy=ddp_find_unused_parameters_true \
    +lightning.trainer.params.val_check_interval=1.0 \
    lightning.trainer.params.accumulate_grad_batches=2 \
    data_loader.params.batch_size=${BATCH_SIZE:-4} \
    data_loader.params.num_workers=${NUM_WORKERS:-8} \
    worker=single_machine_thread_pool \
    model=${MODEL:-gump_nuplan_llama_sm_v1_1} \
    optimizer=adamw \
    optimizer.lr=1e-4 \
    optimizer.weight_decay=1e-3 \
    lr_scheduler=multistep_lr \
    lr_scheduler.milestones=[8,13] \
    lr_scheduler.gamma=0.2 \
    lightning.trainer.checkpoint.resume_training=false \
    scenario_filter=all_scenarios \
    +checkpoint.ckpt_path=${CKPT_PATH:-null} \
    +checkpoint.strict=True \
    +checkpoint.resume=False \
    "$@"
