#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool
id: star_solo
label: STARsolo single-cell alignment and quantification

doc: |
  Aligns single-cell RNA-seq reads with STAR in STARsolo mode, producing
  a coordinate-sorted BAM, a per-cell gene-count matrix, and the run log.
  cDNA reads are passed as read 1 and the cell barcode + UMI read as read 2
  (STARsolo convention: --readFilesIn <cDNA> <barcode>).

requirements:
  DockerRequirement:
    dockerPull: quay.io/biocontainers/star:2.7.11b--h43eeafb_1
  InlineJavascriptRequirement: {}
  ResourceRequirement:
    coresMin: 8
    ramMin: 32000

baseCommand: [STAR]

inputs:
  genome_dir:
    type: Directory
    label: STAR genome index directory
    inputBinding:
      prefix: --genomeDir
  cdna_reads:
    type: File
    label: cDNA FASTQ (read 2 biologically, R1 position for STARsolo)
  barcode_reads:
    type: File
    label: Cell barcode + UMI FASTQ
  whitelist:
    type: File
    label: Cell barcode whitelist (e.g. 10x 737K barcodes)
    inputBinding:
      prefix: --soloCBwhitelist
  cb_length:
    type: int
    default: 16
    inputBinding:
      prefix: --soloCBlen
  umi_length:
    type: int
    default: 12
    inputBinding:
      prefix: --soloUMIlen
  threads:
    type: int
    default: 8
    inputBinding:
      prefix: --runThreadN
  sample_id:
    type: string
    default: sample
    inputBinding:
      prefix: --outFileNamePrefix
      valueFrom: $(self)_

arguments:
  - prefix: --soloType
    valueFrom: CB_UMI_Simple
  - prefix: --readFilesIn
    # STARsolo order: cDNA read first, then barcode read
    valueFrom: $(inputs.cdna_reads.path) $(inputs.barcode_reads.path)
  - prefix: --readFilesCommand
    valueFrom: zcat
  - prefix: --outSAMtype
    valueFrom: BAM SortedByCoordinate
  - prefix: --soloFeatures
    valueFrom: Gene

outputs:
  bam:
    type: File
    outputBinding:
      glob: "*Aligned.sortedByCoord.out.bam"
  solo_matrix:
    type: Directory
    outputBinding:
      glob: "*Solo.out"
  log_final:
    type: File
    outputBinding:
      glob: "*Log.final.out"
