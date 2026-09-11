#!/usr/bin/env python3
"""Filter SAM reads by the number of matched bases in the CIGAR string."""

import argparse

import pysam


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Retain read names with enough matched bases in the CIGAR string."
    )
    parser.add_argument("sam_file", help="SAM file after BLAST filtering")
    parser.add_argument(
        "--match-threshold",
        type=int,
        default=300,
        help="Minimum matched bases required to retain a read. Default: 300",
    )
    parser.add_argument(
        "--gap-threshold",
        type=int,
        default=5,
        help="Maximum non-match operation length allowed before stopping CIGAR parsing. Default: 5",
    )
    parser.add_argument(
        "--output",
        default="cigar_processed_reads.txt",
        help="Output file containing retained read names. Default: cigar_processed_reads.txt",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()

    true_hit_reads = []
    print("Successfully imported SAM file")

    sam_file = pysam.AlignmentFile(args.sam_file)

    print("Parsing through sample")
    for read in sam_file.fetch():
        matched_bases = 0

        for operation, length in read.cigartuples:
            if operation == 4:
                continue
            if operation != 0:
                if length <= args.gap_threshold:
                    continue
                break
            matched_bases += length

        if matched_bases >= args.match_threshold:
            true_hit_reads.append(read.query_name)

    print("Successfully parsed through SAM file")

    with open(args.output, "w", encoding="utf-8") as handle:
        handle.write("\n".join(true_hit_reads))


if __name__ == "__main__":
    main()

