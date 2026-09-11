# Files Needed Before Public Release

The uploaded scripts show the overall workflow, but the original pipeline also
depends on several files that were not included in this upload.

## Configuration Files

- `barcodes.csv`; use `config/barcodes.example.csv` as a structural template
- Guppy custom barcoding template TOML file

## Reference Files

These should usually not be committed directly if they are large or licensed.
Instead, document how to obtain them and how to place them locally.

- Human reference genome FASTA, originally `Homosapiens_GRCh38.p14.fna`
- Tick-borne pathogen mapping FASTA, included as `references/genome.fasta`
- Original BLAST database source FASTA or complete database file set, originally
  `Tick-borne_db/bacterial_and_common_protozoa_genomes`; this was not available
  during repository reconstruction. A rebuild command using the included
  `references/genome.fasta` is provided in `docs/reference_database_setup.md`.

For a complete prebuilt nucleotide BLAST database, each database volume needs
matching `.nhr`, `.nin`, and `.nsq` files. The `.nhr` and `.nin` files alone are
not sufficient to run BLAST.

## Important Sanitization Notes

Before public upload:

- Remove any patient/sample identifiers that should not be public.
- Remove institution-specific absolute paths.
- Remove raw FASTQ, BAM, SAM, VCF, CSV output, and log files.
- Confirm whether the Guppy data files can be redistributed.
- Confirm the intended license.
