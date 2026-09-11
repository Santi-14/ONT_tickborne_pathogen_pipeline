# Reference and BLAST Database Setup

This pipeline uses two reference resources:

1. A host reference genome for host read depletion.
2. A tick-borne pathogen reference set for mapping and BLAST confirmation.

## Host Reference

The original workflow used a human genome reference named:

```text
Homosapiens_GRCh38.p14.fna
```

Place the host FASTA locally and set `HOST_REF` in `config/pipeline.env`.

## Tick-Borne Pathogen Mapping Reference

The original workflow used a pathogen mapping FASTA named:

```text
genome.fasta
```

This repository includes the current `genome.fasta` in `references/`.

```text
references/genome.fasta
references/genome_manifest.tsv
references/genome.fasta.sha256
```

The uploaded folder also contained `genome_old.fasta`, which has a different
checksum and a different number of records. It is not included here because the
current workflow points to `genome.fasta`.

## BLAST Database

The original workflow used a BLAST nucleotide database named:

```text
bacterial_and_common_protozoa_genomes
```

BLAST databases are binary index files generated from a source FASTA. For a
volume-split nucleotide database, each numbered volume usually contains matching
files such as:

```text
bacterial_and_common_protozoa_genomes.00.nhr
bacterial_and_common_protozoa_genomes.00.nin
bacterial_and_common_protozoa_genomes.00.nsq
```

The `.nhr` and `.nin` files are not sufficient by themselves. The corresponding
`.nsq` files are required because they contain the encoded nucleotide sequence
data.

The source FASTA used to create the original
`bacterial_and_common_protozoa_genomes` BLAST database was not available during
repository reconstruction. Therefore, the original prebuilt BLAST database is
not included in this repository.

For reproducible reruns using the included pathogen mapping reference, a local
BLAST database can be built from `references/genome.fasta`:

```bash
mkdir -p databases/Tick-borne_db

makeblastdb \
  -in references/genome.fasta \
  -dbtype nucl \
  -out databases/Tick-borne_db/bacterial_and_common_protozoa_genomes
```

Then set `BLAST_DB` in `config/pipeline.env` to:

```text
/path/to/databases/Tick-borne_db/bacterial_and_common_protozoa_genomes
```

Do not commit large BLAST database binary files to GitHub unless the journal or
reviewers specifically require them and redistribution is permitted.
