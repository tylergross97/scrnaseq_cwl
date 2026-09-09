# Mock scRNA-seq pipeline (CWL)

A minimal single-cell RNA-seq workflow written in [Common Workflow Language](https://www.commonwl.org/) (CWL v1.2). Built as a mock pipeline for demonstrating **CWL → Nextflow conversion** with Co-Scientist.

## Structure

```
scrnaseq_cwl/
├── scrnaseq.cwl          # top-level Workflow wiring the three steps
├── inputs.example.yml    # example job / parameter file
└── tools/
    ├── fastqc.cwl        # CommandLineTool: read QC
    ├── star_solo.cwl     # CommandLineTool: STARsolo alignment + quantification
    └── multiqc.cwl       # CommandLineTool: aggregate QC report
```

## Data flow

```
cdna_reads ─┐
            ├─► fastqc ───► (zip) ─┐
barcode_reads┘                     │
                                   ├─► multiqc ─► report.html
cdna_reads ─┐                      │
barcode_reads├─► star_solo ─► BAM  │
genome_dir  │              ├ Solo.out (count matrix)
whitelist   ┘              └ Log.final.out ──────┘
```

1. **fastqc** — quality control on the cDNA and barcode FASTQs.
2. **star_solo** — STARsolo alignment producing a sorted BAM, a per-cell
   gene-count matrix (`*Solo.out`), and the STAR run log.
3. **multiqc** — aggregates the FastQC zips and STAR log into one HTML report.

## Running

Requires a CWL runner (e.g. [`cwltool`](https://github.com/common-workflow-language/cwltool)) and Docker:

```bash
cwltool scrnaseq.cwl inputs.example.yml
```

The paths in `inputs.example.yml` are placeholders — point them at real 10x
FASTQs, a STAR index, and a barcode whitelist to actually execute.

## Notes

- Tool versions are pinned to Biocontainers images (STAR 2.7.11b, FastQC
  0.12.1, MultiQC 1.21).
- STARsolo `--readFilesIn` order is `<cDNA> <barcode>`, i.e. 10x R2 then R1.
