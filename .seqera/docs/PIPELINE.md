# Mock scRNA-seq Pipeline (STARsolo)

> Last updated: 2026-09-09

## Overview

A minimal single-cell RNA-seq workflow written in [Common Workflow Language](https://www.commonwl.org/)
(CWL v1.2). It runs read QC, STARsolo alignment with per-cell gene
quantification, and aggregates QC into a single report. It is a mock/demo
pipeline built to demonstrate **CWL → Nextflow conversion** with Co-Scientist.

## Quick Start

```bash
cwltool scrnaseq.cwl inputs.example.yml
```

Requires a CWL runner (e.g. [`cwltool`](https://github.com/common-workflow-language/cwltool))
and Docker. The paths in `inputs.example.yml` are placeholders — point them at
real 10x FASTQs, a STAR index, and a barcode whitelist to actually execute.

## Inputs

Inputs are supplied via a CWL job file (see `inputs.example.yml`):

| Input           | Type      | Description                                            |
|-----------------|-----------|--------------------------------------------------------|
| `sample_id`     | string    | Sample identifier used to prefix STAR outputs.         |
| `cdna_reads`    | File      | cDNA FASTQ (10x R2).                                    |
| `barcode_reads` | File      | Cell barcode + UMI FASTQ (10x R1).                      |
| `genome_dir`    | Directory | Pre-built STAR genome index.                           |
| `whitelist`     | File      | Cell barcode whitelist (e.g. 10x 737K barcodes).       |
| `cb_length`     | int       | Cell barcode length (default 16).                      |
| `umi_length`    | int       | UMI length (default 12).                               |
| `threads`       | int       | Threads for FastQC and STAR (default 8).               |

Input file locations vary per project — do not assume a fixed bucket or path.

## Key Parameters

| Parameter    | Description                              | Default  | Notes                                             |
|--------------|------------------------------------------|----------|---------------------------------------------------|
| `sample_id`  | Prefix for STAR output filenames         | `sample` | Set per sample (e.g. `pbmc_1k`).                  |
| `cb_length`  | Cell barcode length (`--soloCBlen`)      | `16`     | 10x v2/v3 use 16 bp barcodes.                     |
| `umi_length` | UMI length (`--soloUMIlen`)              | `12`     | 10x v2 = 10 bp, v3 = 12 bp — adjust per chemistry.|
| `threads`    | Thread count for FastQC / STAR           | `8`      | Passed to `--threads` and `--runThreadN`.         |

## Workflow Structure

- **Entry point**: `scrnaseq.cwl` — top-level `Workflow` wiring three steps.
- **Steps**:
  - `fastqc` (`tools/fastqc.cwl`) — read QC on cDNA + barcode FASTQs; emits HTML + zip reports.
  - `star_solo` (`tools/star_solo.cwl`) — STARsolo alignment; emits sorted BAM, per-cell count matrix (`*Solo.out`), and `Log.final.out`.
  - `multiqc` (`tools/multiqc.cwl`) — aggregates FastQC zips + STAR log into one HTML report.

### Data flow

```
cdna_reads ─┬─► fastqc ──► zip_reports ─┐
barcode_reads┘                          ├─► multiqc ─► multiqc_report.html
cdna_reads ─┬─► star_solo ─► BAM        │
barcode_reads│            ├ Solo.out    │
genome_dir   │            └ Log.final.out ┘
whitelist   ─┘
```

Note the STARsolo read order: `--readFilesIn <cDNA> <barcode>` (10x R2 then R1).

## Outputs

| Output           | Type      | Source                  | Description                               |
|------------------|-----------|-------------------------|-------------------------------------------|
| `fastqc_html`    | File[]    | `fastqc/html_reports`   | Per-FASTQ FastQC HTML reports.            |
| `aligned_bam`    | File      | `star_solo/bam`         | Coordinate-sorted alignment BAM.          |
| `count_matrix`   | Directory | `star_solo/solo_matrix` | Per-cell gene-count matrix (`*Solo.out`). |
| `star_log`       | File      | `star_solo/log_final`   | STAR `Log.final.out` summary.             |
| `multiqc_report` | File      | `multiqc/report`        | Aggregated MultiQC HTML report.           |

## Requirements

- **CWL**: v1.2 (workflow-level requirements: `MultipleInputFeatureRequirement`, `StepInputExpressionRequirement`, `InlineJavascriptRequirement`).
- **Runner**: `cwltool` or any CWL v1.2-compatible engine.
- **Container runtime**: Docker (all tools pull Biocontainers images).
- **Reference data**: pre-built STAR genome index + cell barcode whitelist.

### Pinned tool containers

| Tool    | Container image                                     |
|---------|-----------------------------------------------------|
| FastQC  | `quay.io/biocontainers/fastqc:0.12.1--hdfd78af_0`   |
| STAR    | `quay.io/biocontainers/star:2.7.11b--h43eeafb_1`    |
| MultiQC | `quay.io/biocontainers/multiqc:1.21--pyhdfd78af_0`  |
