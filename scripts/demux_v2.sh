#!/usr/bin/env bash
set -euo pipefail

format_time() {
  local total_seconds=$1
  printf "%02d:%02d:%02d\n" \
    $((total_seconds / 3600)) \
    $(((total_seconds % 3600) / 60)) \
    $((total_seconds % 60))
}

if [[ $# -lt 3 ]]; then
  echo "Usage: $0 <analysis_folder> <project_name> <pipeline_env>" >&2
  exit 1
fi

analysis_folder=$1
project=$2
pipeline_env=$3

# shellcheck source=/dev/null
source "$pipeline_env"

cd "$analysis_folder"

mkdir -p Raw_fastq demuxed_data_95
mv ./*.fastq.gz Raw_fastq/

python3 "${PIPELINE_DIR}/scripts/demux_fasta_file_creation.py" \
  "$BARCODES_CSV" \
  "$project" \
  "$BARCODING_TEMPLATE_TOML"

mv custom_barcodes.fasta "${GUPPY_DATA_PATH}/custom_barcodes_${project}.fasta"
mv "barcode_arrs_dual_${project}.toml" "${GUPPY_DATA_PATH}/barcoding_arrangements/barcode_arrs_dual_custom.toml"

"$GUPPY_BARCODER" \
  --input_path ./Raw_fastq \
  --save_path ./demuxed_data_95 \
  --data_path "$GUPPY_DATA_PATH" \
  --barcode_kits "$project" \
  -q 0 \
  --front_window_size 80 \
  --rear_window_size 80 \
  --min_score_barcode_front "$MIN_BARCODE_SCORE" \
  --min_score_barcode_rear "$MIN_BARCODE_SCORE"

cd demuxed_data_95

for barcode_dir in */; do
  barcode_name=${barcode_dir%/}

  if [[ "$barcode_name" == *unclassified* ]]; then
    (cd "$barcode_dir" && mv ./*.fastq ../unclassified.fastq)
    continue
  fi

  barcode_num=${barcode_name#custom_barcode}
  modulo=$((10#$barcode_num % 2))

  if [[ "$modulo" -eq 1 ]]; then
    next_num=$((10#$barcode_num + 1))
    printf -v formatted_next "%02d" "$next_num"
    merged_num=$(((10#$barcode_num + 1) / 2))
    cat "${barcode_dir}"/*.fastq "custom_barcode${formatted_next}"/*.fastq > "barcode${merged_num}.fastq"
  fi
done

gzip -f ./*.fastq
rm -rf ./*/

rm -f "${GUPPY_DATA_PATH}/barcoding_arrangements/barcode_arrs_dual_custom.toml"
rm -f "${GUPPY_DATA_PATH}/custom_barcodes_${project}.fasta"

echo "Script completed in $(format_time "$SECONDS")"

