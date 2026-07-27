# TAP-SID

Official implementation of **Task-aligned Prefix Semantic ID (TAP-SID)** for generative next-POI prediction, accompanying the paper:

> **Beyond Item Identification: Task-aligned Semantic ID Prefixes for Generative Next-POI Prediction**

## Overview

Generative next-POI prediction represents each target POI as a sequence of discrete tokens and generates its identifier autoregressively. Existing quantization-based Semantic IDs mainly optimize complete identifiers, although intermediate prefixes also partition the POI catalog and shape subsequent decoding decisions.TAP-SID explicitly constructs a progressive decision path from POI coordinates and hierarchical categories: coarse region -> fine region -> L1 category -> L2 category -> leaf. The complete path uniquely identifies a POI, while successive prefixes perform spatial localization, functional refinement, and entity discrimination. TAP-SID directly serves as the fine-tuning target without requiring a separately trained residual-quantization codebook. During inference, catalog-constrained decoding restricts generation to valid POI paths.

## Data and Setup

Place a TSMC2014 NYC or TKY data file under `data/raw/`. Each row should contain:

```text
user_id, poi_id, category_id, category_name,
latitude, longitude, timezone_offset, utc_time
```

The preprocessing pipeline chronologically splits the data, retains users and POIs observed in the training set, constructs next-POI samples, and generates the TAP-SID codebook. The fixed mapping from fine-grained categories to L1 categories is included in the repository. Create and load a local configuration file:

```bash
cp configs/example.env configs/local.env

set -a
source configs/local.env
set +a
export PYTHONPATH=$PWD
```

The experiments use `Meta-Llama-3-8B-Instruct` and were conducted on two NVIDIA GeForce RTX 4090D GPUs with 24 GB of memory each.

## Run

Run data preparation, training, and evaluation sequentially:

```bash
bash scripts/prepare_data.sh
bash scripts/train.sh
bash scripts/evaluate.sh
```

Training uses LoRA. Evaluation uses catalog-constrained beam search and reports Recall@1/5/10 and NDCG@1/5/10. The main outputs are stored under`RUN_ROOT/`:

```text
RUN_ROOT/
  codebook/tap_sid.csv
  data/llm_train.json
  data/llm_val.json
  data/llm_test.json
  checkpoint/final_sft/
  checkpoint/training_summary.json
  eval/test_predictions.json
  eval/test_metrics.json
```

## Citation

Citation information will be added after publication.
