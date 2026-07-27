#!/usr/bin/env bash
set -euo pipefail

: "${TSMC_FILE:?Set TSMC_FILE}"
: "${TSMC_CATEGORY_L1_MAP:?Set TSMC_CATEGORY_L1_MAP}"
: "${PROCESSED_ROOT:?Set PROCESSED_ROOT}"
: "${RUN_ROOT:?Set RUN_ROOT}"
: "${TRAIN_END:?Set TRAIN_END}"
: "${VALIDATION_END:?Set VALIDATION_END}"

TSMC_ENCODING=${TSMC_ENCODING:-latin-1}
DEFAULT_TIMEZONE_OFFSET_MINUTES=${DEFAULT_TIMEZONE_OFFSET_MINUTES:-0}
N_COARSE_REGIONS=${N_COARSE_REGIONS:-64}
N_FINE_REGIONS=${N_FINE_REGIONS:-256}
MAX_SEQUENCE_LENGTH=${MAX_SEQUENCE_LENGTH:-50}
MIN_HISTORY_LENGTH=${MIN_HISTORY_LENGTH:-19}
KEEP_LAST_K_TRAIN=${KEEP_LAST_K_TRAIN:-5}

CONVERTED_DIR="$PROCESSED_ROOT/converted_raw"
EVENTS="$CONVERTED_DIR/events.csv"
POIS="$CONVERTED_DIR/pois.csv"
SID_CSV="$RUN_ROOT/codebook/tap_sid.csv"
mkdir -p "$CONVERTED_DIR" "$RUN_ROOT/codebook" "$RUN_ROOT/data"

python -m tap_sid.convert_tsmc2014 \
  --input "$TSMC_FILE" \
  --events_output "$EVENTS" \
  --pois_output "$POIS" \
  --report_output "$CONVERTED_DIR/conversion_report.json" \
  --category_l1_map "$TSMC_CATEGORY_L1_MAP" \
  --encoding "$TSMC_ENCODING"

python -m tap_sid.prepare_realworld_data \
  --events "$EVENTS" \
  --pois "$POIS" \
  --output_dir "$PROCESSED_ROOT" \
  --train_end "$TRAIN_END" \
  --validation_end "$VALIDATION_END" \
  --default_timezone_offset_minutes "$DEFAULT_TIMEZONE_OFFSET_MINUTES" \
  --max_sequence_length "$MAX_SEQUENCE_LENGTH" \
  --min_history_length "$MIN_HISTORY_LENGTH" \
  --catalog_scope train_seen

python -m tap_sid.build_tap_sid \
  --poi_info "$PROCESSED_ROOT/poi_info.csv" \
  --role_priors "$PROCESSED_ROOT/role_priors.csv" \
  --output_csv "$SID_CSV" \
  --report_json "$RUN_ROOT/codebook/tap_sid_report.json" \
  --n_coarse_regions "$N_COARSE_REGIONS" \
  --n_fine_regions "$N_FINE_REGIONS" \
  --seed 2024

python -m tap_sid.build_llm_data \
  --sid_csv "$SID_CSV" \
  --split_dir "$PROCESSED_ROOT/v1_sequence" \
  --output_dir "$RUN_ROOT/data" \
  --keep_last_k_train "$KEEP_LAST_K_TRAIN"

echo "Prepared TAP-SID data: $RUN_ROOT"
