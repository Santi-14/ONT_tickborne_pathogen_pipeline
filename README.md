# ONT Tick-Borne Pathogen Analysis Pipeline

This repository contains the Oxford Nanopore Technologies (ONT) sequencing
analysis pipeline used for tick-borne pathogen sequencing analysis.

The workflow concatenates raw FASTQ files, demultiplexes reads using custom
dual-barcoding definitions, removes host reads, maps remaining reads to a
tick-borne pathogen reference database, filters mapped reads, and generates
per-sample coverage summaries.

## Workflow

1. Concatenate raw `fastq.gz` files into one project-level FASTQ.
2. Demultiplex the project FASTQ using Guppy barcoder and custom barcode files.
3. Trim and quality-filter demultiplexed reads with `fastp`.
4. Remove host reads by mapping to the human reference genome with `minimap2`.
5. Map non-host reads to the tick-borne pathogen reference FASTA.
6. BLAST candidate reads against a curated tick-borne organism database.
7. Filter reads by BLAST result, CIGAR alignment length, MAPQ, and supplementary alignment flag.
8. Generate sorted/indexed BAM files and coverage summary CSV files.

## Repository Contents

The shell and Python scripts in `scripts/` correspond to the analysis workflow used for ONT sequencing data processing in this study.

Included reference files:

- `references/genome.fasta`: tick-borne pathogen mapping reference used by the pipeline
- `references/genome_manifest.tsv`: accession and description manifest for `genome.fasta`
- `references/genome.fasta.sha256`: checksum for the included reference FASTA

## Reference Files

The tick-borne pathogen mapping reference used by the pipeline is included in `references/genome.fasta`, with an accession manifest and checksum.

The workflow requires users to configure local paths for the host reference genome, ONT/Guppy barcoding resources, and any BLAST database used for confirmation. See `docs/reference_database_setup.md` for setup details.

Do not commit patient/sample sequencing data, FASTQ files, BAM files, or analysis
outputs to this repository.

## Dependencies

The pipeline expects the following command-line tools:

- Bash
- `gzip`/`gunzip` or `gzcat`/`zcat`
- ONT Guppy barcoder
- `fastp`
- `minimap2`
- `samtools`
- `bedtools`
- BLAST+ (`blastn`, `makeblastdb`)
- Python 3

Python package dependencies are listed in `requirements.txt`.

## Basic Usage

Edit `config/pipeline.env.example`, copy it to `config/pipeline.env`, and update
the paths to your local installation and reference files.

```bash
cp config/pipeline.env.example config/pipeline.env
```

Run the full wrapper:

```bash
bash scripts/nanopore_analysis_wrapper.sh /path/to/raw_fastq_folder PROJECT_NAME config/pipeline.env
```

Arguments:

- `/path/to/raw_fastq_folder`: folder containing raw `.fastq.gz` files from one project/run
- `PROJECT_NAME`: project/sample-set name with no spaces
- `config/pipeline.env`: environment file containing local paths

## Output

The workflow creates an `analysis/` directory containing:

- concatenated project FASTQ
- demultiplexed per-barcode FASTQ files
- per-barcode result folders
- sorted BAM files and `.bai` indexes
- per-sample coverage CSV files
- merged project-level coverage CSV

## Citation

If used in a manuscript, cite the GitHub repository release or Zenodo DOI once a
stable release has been created.
