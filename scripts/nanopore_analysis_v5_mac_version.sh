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
  echo "Usage: $0 <demuxed_fastq_folder> <pipeline_env>" >&2
  exit 1
fi

demuxed_fastq_folder=$1
pipeline_env=$2

# shellcheck source=/dev/null
source "$pipeline_env"

echo "Tick-borne disease nanopore analysis pipeline"

cd "$demuxed_fastq_folder"

for raw_fastq in ./*.fastq.gz; do
  raw_fastq=$(basename "$raw_fastq")
  results_dir="${raw_fastq}_results"

  mkdir -p "$results_dir"
  mv "$raw_fastq" "$results_dir/"
  cd "$results_dir"

  echo "Filtering $raw_fastq"
  fastp \
    -i "$raw_fastq" \
    -o "${raw_fastq}_filt_trim_reads.fastq.gz" \
    --length_required "$MIN_READ_LENGTH" \
    --qualified_quality_phred "$MIN_PHRED_QUALITY"

  echo "Mapping $raw_fastq to host genome"
  minimap2 -ax map-ont "$HOST_REF" "${raw_fastq}_filt_trim_reads.fastq.gz" -o output.sam

  echo "Removing host-mapped reads from $raw_fastq"
  samtools view -f 4 output.sam > unmapped_reads.sam
  rm -f output.sam

  samtools fasta unmapped_reads.sam > unmapped_reads.fasta
  rm -f unmapped_reads.sam

  echo "Mapping non-host reads to pathogen reference"
  minimap2 -ax map-ont "$PATHOGEN_REF" unmapped_reads.fasta --sam-hit-only -o mapped_reads.sam

  grep "^@" mapped_reads.sam > sam_header.txt

  echo "Filtering mapped reads in $raw_fastq for MAPQ > $MIN_MAPQ"
  samtools view mapped_reads.sam | awk -v min_mapq="$MIN_MAPQ" '$10 != "*" && $5 > min_mapq {print $0}' > filtered_mapped_reads.sam

  cat sam_header.txt filtered_mapped_reads.sam > total_filt_map_reads.sam
  rm -f sam_header.txt

  samtools fasta total_filt_map_reads.sam > total_filt_map_reads.fasta

  echo "Blasting candidate reads against tick-borne database"
  blastn \
    -task megablast \
    -db "$BLAST_DB" \
    -query total_filt_map_reads.fasta \
    -outfmt "6 qseqid sseqid stitle" \
    -max_target_seqs 1 \
    -out blasted_seqs.txt \
    -num_threads "$THREADS"

  echo "Parsing BLAST output"
  python3 "${PIPELINE_DIR}/scripts/blast_processing.py" blasted_seqs.txt "$PATHOGEN_REF"

  awk 'NR==FNR { ids[$1]; next } $1 ~ /^@/ || $1 in ids' important_seq_ids.txt total_filt_map_reads.sam > blast_filtered_reads.sam

  echo "Filtering by CIGAR string"
  python3 "${PIPELINE_DIR}/scripts/cigar_processing.py" blast_filtered_reads.sam

  awk 'NR==FNR { ids[$1]; next } $1 ~ /^@/ || $1 in ids' cigar_processed_reads.txt blast_filtered_reads.sam > cigar_filtered_reads.sam

  echo "Removing supplementary alignments"
  samtools view -h -F 0x800 cigar_filtered_reads.sam > no_supp_cigar_filt.sam

  echo "Generating sorted BAM file"
  samtools view no_supp_cigar_filt.sam -b -o filtered_seqs_mapped.bam
  samtools sort filtered_seqs_mapped.bam -o "${raw_fastq}_sorted_map_seqs.bam"
  samtools index "${raw_fastq}_sorted_map_seqs.bam"

  echo "Obtaining mapping statistics"
  bedtools genomecov -ibam "${raw_fastq}_sorted_map_seqs.bam" > coverage.txt
  samtools idxstats "${raw_fastq}_sorted_map_seqs.bam" > reads_mapped.txt

  echo "Creating coverage report"
  python3 "${PIPELINE_DIR}/scripts/nanopore_map_stat.py" \
    "$raw_fastq" \
    "${raw_fastq}_filt_trim_reads.fastq.gz" \
    "$PATHOGEN_REF" \
    coverage.txt \
    reads_mapped.txt

  rm -f coverage.txt reads_mapped.txt "${raw_fastq}_filt_trim_reads.fastq.gz" fastp.json

  cd ..
done

project=$(basename "$(dirname "$demuxed_fastq_folder")")
cat ./*/*.csv > "${project}_total_coverage.csv"

echo "Script completed in $(format_time "$SECONDS")"

