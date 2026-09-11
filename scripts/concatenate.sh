#!/usr/bin/env bash
set -euo pipefail

format_time() {
  local total_seconds=$1
  printf "%02d:%02d:%02d\n" \
    $((total_seconds / 3600)) \
    $(((total_seconds % 3600) / 60)) \
    $((total_seconds % 60))
}

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <raw_fastq_folder> <project_name>" >&2
  exit 1
fi

raw_fastq_folder=$1
project=$2

cd "$raw_fastq_folder"
mkdir -p analysis

if command -v gzcat >/dev/null 2>&1; then
  gzcat ./*.gz > "analysis/${project}.fastq"
else
  zcat ./*.gz > "analysis/${project}.fastq"
fi

gzip -f "analysis/${project}.fastq"

echo "Script completed in $(format_time "$SECONDS")"

