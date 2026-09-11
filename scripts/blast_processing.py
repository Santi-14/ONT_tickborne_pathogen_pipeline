#!/usr/bin/env python3
"""Filter BLAST hits to reads matching genera present in the reference FASTA."""

import sys
from pathlib import Path

import pandas as pd


def reference_genera(ref_genome: Path) -> list[str]:
    genera = []

    with ref_genome.open("r", encoding="utf-8") as handle:
        for line in handle:
            if not line.startswith(">"):
                continue
            fields = line[1:].strip().split()
            if len(fields) >= 2:
                genera.append(fields[1])

    if "Borreliella" in genera:
        genera.append("Borrelia")

    return genera


def main() -> None:
    if len(sys.argv) != 3:
        sys.exit("Usage: blast_processing.py <blast_output.tsv> <reference_genome.fasta>")

    blast_file = Path(sys.argv[1])
    ref_genome = Path(sys.argv[2])

    blast_df = pd.read_csv(blast_file, sep="\t", header=None)
    valid_genera = set(reference_genera(ref_genome))

    selected_seq_ids = []

    for seq_id, title in zip(blast_df[0], blast_df[2]):
        title_fields = str(title).split()
        if len(title_fields) < 2:
            continue
        genus = title_fields[1]
        if genus in valid_genera:
            selected_seq_ids.append(seq_id)

    with open("important_seq_ids.txt", "w", encoding="utf-8") as handle:
        handle.write("\n".join(selected_seq_ids))


if __name__ == "__main__":
    main()

