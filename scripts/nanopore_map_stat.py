#!/usr/bin/env python3
"""Create per-reference mapping and coverage statistics for one ONT sample."""

import gzip
import sys
from pathlib import Path

import pandas as pd


def count_fastq_reads(fastq_gz: Path) -> int:
    line_count = 0
    with gzip.open(fastq_gz, "rt", encoding="utf-8") as handle:
        for line_count, _line in enumerate(handle, start=1):
            pass
    return line_count // 4


def fasta_reference_names(ref_genome: Path) -> dict[str, str]:
    names = {}
    with ref_genome.open("r", encoding="utf-8") as handle:
        for line in handle:
            if not line.startswith(">"):
                continue
            header = line[1:].strip()
            fields = header.split(maxsplit=1)
            ref_id = fields[0]
            ref_name = fields[1] if len(fields) > 1 else ref_id
            names[ref_id] = ref_name
    return names


def main() -> None:
    if len(sys.argv) != 6:
        sys.exit(
            "Usage: nanopore_map_stat.py <raw.fastq.gz> <filtered.fastq.gz> "
            "<reference_genome.fasta> <bedtools_genomecov.txt> <samtools_idxstats.txt>"
        )

    raw_fastq = Path(sys.argv[1])
    filtered_fastq = Path(sys.argv[2])
    ref_genome = Path(sys.argv[3])
    coverage_file = Path(sys.argv[4])
    reads_file = Path(sys.argv[5])

    coverage = pd.read_table(coverage_file, sep="\t", header=None)
    reads = pd.read_table(reads_file, sep="\t", header=None)

    coverage = coverage[coverage[0] != "genome"]
    reads = reads[reads[0] != "*"].copy()

    reference_genomes = []
    reference_lengths = []
    covered_bases = {}
    total_coverage = {}

    for _index, row in coverage.iterrows():
        ref_id = row[0]
        depth = int(row[1])
        bases_at_depth = int(row[2])
        ref_length = int(row[3])

        if ref_id not in covered_bases:
            reference_genomes.append(ref_id)
            reference_lengths.append(ref_length)
            covered_bases[ref_id] = 0
            total_coverage[ref_id] = 0

        if depth != 0:
            covered_bases[ref_id] += bases_at_depth
            total_coverage[ref_id] += depth * bases_at_depth

    raw_read_count = count_fastq_reads(raw_fastq)
    filtered_read_count = count_fastq_reads(filtered_fastq)
    ref_names = fasta_reference_names(ref_genome)

    coverage_data = []

    for ref_id, ref_length in zip(reference_genomes, reference_lengths):
        mapped_row = reads[reads[0] == ref_id]
        mapped_reads = int(mapped_row.iloc[0, 2]) if not mapped_row.empty else 0

        coverage_data.append(
            {
                "Sample ID": raw_fastq.name,
                "Number Raw Reads": raw_read_count,
                "Number Filtered Reads": filtered_read_count,
                "Number Mapped": mapped_reads,
                "Percentage Reads Mapped": mapped_reads / filtered_read_count * 100
                if filtered_read_count
                else 0,
                "Reference ID": ref_id,
                "Reference Name": ref_names.get(ref_id, ref_id),
                "Reference Length": ref_length,
                "Percentage Genome Recovered": covered_bases[ref_id] / ref_length * 100
                if ref_length
                else 0,
                "Average Coverage": total_coverage[ref_id] / ref_length if ref_length else 0,
            }
        )

    stats_df = pd.DataFrame(coverage_data)
    stats_df.to_csv(f"{raw_fastq.name}.coverage.csv", index=False)


if __name__ == "__main__":
    main()

