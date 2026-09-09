# Pipeline Patterns

> Last updated: 2026-09-09

Aggregate patterns observed across the pipeline's configuration. This file
describes **tendencies and conventions**, not specific runs.

## Configuration Conventions

### Containerization

All tools run in pinned Biocontainers Docker images (declared via
`DockerRequirement.dockerPull`). There are no `latest` tags — every tool
version is fixed, which keeps runs reproducible.

| Tool    | Version  | Image                                               |
|---------|----------|-----------------------------------------------------|
| FastQC  | 0.12.1   | `quay.io/biocontainers/fastqc:0.12.1--hdfd78af_0`   |
| STAR    | 2.7.11b  | `quay.io/biocontainers/star:2.7.11b--h43eeafb_1`    |
| MultiQC | 1.21     | `quay.io/biocontainers/multiqc:1.21--pyhdfd78af_0`  |

### Threading Convention

A single `threads` workflow input (default 8) fans out to both FastQC
(`--threads`) and STAR (`--runThreadN`). Tune once at the workflow level
rather than per tool.

## Resource Patterns

Only the `star_solo` step declares explicit resource requirements. Values
below come from the CWL `ResourceRequirement` blocks, not from run telemetry.

| Step        | `coresMin` | `ramMin`  | Notes                                             |
|-------------|-----------:|----------:|---------------------------------------------------|
| `fastqc`    | —          | —         | No explicit reservation; lightweight QC.          |
| `star_solo` | 8          | 32000 MB  | STAR memory scales with genome index size.        |
| `multiqc`   | —          | —         | No explicit reservation; report aggregation only. |

> No aggregate Platform run data was available (this is a mock/demo CWL
> pipeline that has not been executed on Seqera Platform). CPU-efficiency,
> memory-headroom, and runtime-distribution tables cannot be populated yet.

## Optimization Notes

Derived only from the declared configuration above:

- **`star_solo`** reserves 32 GB RAM and 8 cores — the dominant resource
  consumer. Real memory need is driven by STAR index size; a genome-scale
  index typically needs ≥ 32 GB, while small demo references need far less.
- **`fastqc`** and **`multiqc`** declare no resource floor — both are light
  and safe to run with modest defaults.
- Set `umi_length` to match 10x chemistry (v2 = 10 bp, v3 = 12 bp); the
  default of 12 assumes v3.

## Input Location Conventions

Input data locations vary per project — do **not** assume a single bucket or
prefix. The pipeline expects:

- A cDNA FASTQ and a barcode FASTQ (10x R2 / R1 respectively).
- A pre-built STAR genome index **directory**.
- A cell barcode whitelist file matching the assay chemistry.

The example job file (`inputs.example.yml`) uses placeholder relative paths
(`data/`, `reference/`) — replace them with real locations at run time.
