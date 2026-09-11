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
  echo "Usage: $0 <raw_fastq_folder> <project_name> <pipeline_env>" >&2
  exit 1
fi

raw_fastq_folder=$1
project=$2
pipeline_env=$3

# shellcheck source=/dev/null
source "$pipeline_env"

"${PIPELINE_DIR}/scripts/concatenate.sh" "$raw_fastq_folder" "$project"

analysis_dir="${raw_fastq_folder}/analysis"

"${PIPELINE_DIR}/scripts/demux_v2.sh" "$analysis_dir" "$project" "$pipeline_env"
"${PIPELINE_DIR}/scripts/nanopore_analysis_v5_mac_version.sh" "${analysis_dir}/demuxed_data_95" "$pipeline_env"

cd "${analysis_dir}/demuxed_data_95"
cat ./*/*.csv > "${project}_total_coverage.csv"

echo "Script completed in $(format_time "$SECONDS")"

