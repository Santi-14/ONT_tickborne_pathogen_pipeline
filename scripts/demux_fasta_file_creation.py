#!/usr/bin/env python3
"""Create custom Guppy barcode FASTA and TOML files from a barcode table."""

import sys

import pandas as pd
import toml
from Bio import SeqIO
from Bio.Seq import Seq
from Bio.SeqRecord import SeqRecord


def main() -> None:
    if len(sys.argv) != 4:
        sys.exit(
            "Usage: demux_fasta_file_creation.py <barcodes.csv> <project_name> "
            "<barcode_template.toml>"
        )

    barcode_csv = sys.argv[1]
    project_name = sys.argv[2]
    config_file = sys.argv[3]

    barcodes = pd.read_csv(barcode_csv)
    barcodes = barcodes[pd.notna(barcodes["barcode_id"])]

    sequences = []
    last_index = 0

    for index, row in barcodes.iterrows():
        p5 = Seq(row["p5_barcode"])
        p7 = Seq(row["p7_barcode"])

        sequences.append(SeqRecord(p5, id="FRONT" + str(2 * index + 1).zfill(2), description=""))
        sequences.append(
            SeqRecord(p7.reverse_complement(), id="REAR" + str(2 * index + 1).zfill(2), description="")
        )
        sequences.append(SeqRecord(p5[::-1], id="FRONT" + str(2 * index + 2).zfill(2), description=""))
        sequences.append(
            SeqRecord(p7.complement(), id="REAR" + str(2 * index + 2).zfill(2), description="")
        )
        last_index = 2 * index + 2

    with open("custom_barcodes.fasta", "w", encoding="utf-8") as handle:
        SeqIO.write(sequences, handle, "fasta")

    with open(config_file, "r", encoding="utf-8") as handle:
        config = toml.load(handle)

    config["loading_options"]["barcodes_filename"] = f"custom_barcodes_{project_name}.fasta"
    config["arrangement"]["compatible_kits"] = [project_name]
    config["arrangement"]["last_index"] = last_index

    new_config_file = f"barcode_arrs_dual_{project_name}.toml"

    with open(new_config_file, "w", encoding="utf-8") as handle:
        toml.dump(config, handle)


if __name__ == "__main__":
    main()

