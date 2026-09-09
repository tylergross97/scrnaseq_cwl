#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: Workflow
id: scrnaseq_star
label: Mock single-cell RNA-seq pipeline (STARsolo)

doc: |
  A minimal, demo single-cell RNA-seq workflow:

    1. fastqc      - QC on the cDNA and barcode FASTQs
    2. star_solo   - STARsolo alignment + per-cell gene quantification
    3. multiqc     - aggregate FastQC + STAR logs into one report

  Intended as a mock CWL pipeline to demonstrate conversion to Nextflow.

requirements:
  MultipleInputFeatureRequirement: {}
  StepInputExpressionRequirement: {}
  InlineJavascriptRequirement: {}

inputs:
  sample_id:
    type: string
    default: sample
    doc: Sample identifier used to prefix STAR outputs.
  cdna_reads:
    type: File
    doc: cDNA FASTQ (10x R2).
  barcode_reads:
    type: File
    doc: Cell barcode + UMI FASTQ (10x R1).
  genome_dir:
    type: Directory
    doc: Pre-built STAR genome index.
  whitelist:
    type: File
    doc: Cell barcode whitelist.
  cb_length:
    type: int
    default: 16
  umi_length:
    type: int
    default: 12
  threads:
    type: int
    default: 8

steps:
  fastqc:
    run: tools/fastqc.cwl
    in:
      reads:
        source: [cdna_reads, barcode_reads]
        linkMerge: merge_flattened
      threads: threads
    out: [html_reports, zip_reports]

  star_solo:
    run: tools/star_solo.cwl
    in:
      genome_dir: genome_dir
      cdna_reads: cdna_reads
      barcode_reads: barcode_reads
      whitelist: whitelist
      cb_length: cb_length
      umi_length: umi_length
      threads: threads
      sample_id: sample_id
    out: [bam, solo_matrix, log_final]

  multiqc:
    run: tools/multiqc.cwl
    in:
      qc_files:
        source: [fastqc/zip_reports, star_solo/log_final]
        linkMerge: merge_flattened
    out: [report, data_dir]

outputs:
  fastqc_html:
    type: File[]
    outputSource: fastqc/html_reports
  aligned_bam:
    type: File
    outputSource: star_solo/bam
  count_matrix:
    type: Directory
    outputSource: star_solo/solo_matrix
  star_log:
    type: File
    outputSource: star_solo/log_final
  multiqc_report:
    type: File
    outputSource: multiqc/report
