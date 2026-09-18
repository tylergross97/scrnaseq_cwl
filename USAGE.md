# scrnaseq (Nextflow)

Nextflow DSL2 port of the mock single-cell RNA-seq CWL pipeline. Three steps:

1. **FASTQC** — QC on the cDNA (10x R2) and barcode (10x R1) FASTQs.
2. **STAR_SOLO** — STARsolo alignment + per-cell gene quantification (sorted BAM, `*Solo.out` count matrix, `Log.final.out`).
3. **MULTIQC** — aggregates FastQC zips + STAR logs into one HTML report.

## Layout

```
scrnaseq_cwl/
├── main.nf                     # workflow wiring the three steps
├── nextflow.config             # params, profiles, resource labels
├── nextflow_schema.json        # parameter schema (drives the Platform launch form)
├── conf/modules.config         # per-module ext.args (STARsolo CB/UMI lengths)
├── assets/
│   ├── samplesheet.csv         # example samplesheet
│   └── schema_input.json       # samplesheet row validation
└── modules/local/
    ├── fastqc.nf
    ├── star_solo.nf
    └── multiqc.nf
```

## Input samplesheet

One row per sample:

```csv
sample,cdna_reads,barcode_reads
pbmc_1k,data/pbmc_1k_R2.fastq.gz,data/pbmc_1k_R1.fastq.gz
```

## Running

```bash
nextflow run tylergross97/scrnaseq_cwl \
    -r master \
    -profile docker \
    --input      assets/samplesheet.csv \
    --genome_dir /path/to/star_index \
    --whitelist  /path/to/737K-august-2016.txt \
    --outdir     results
```

## Parameters

| Parameter      | Default | Description                                       |
|----------------|---------|---------------------------------------------------|
| `--input`      | —       | CSV samplesheet (`sample,cdna_reads,barcode_reads`) |
| `--outdir`     | results | Output directory                                  |
| `--genome_dir` | —       | Pre-built STAR genome index directory             |
| `--whitelist`  | —       | Cell barcode whitelist (e.g. 10x 737K)            |
| `--cb_length`  | 16      | Cell barcode length (`--soloCBlen`)               |
| `--umi_length` | 12      | UMI length (`--soloUMIlen`)                       |

Container versions match the original CWL: STAR 2.7.11b, FastQC 0.12.1, MultiQC 1.21.
