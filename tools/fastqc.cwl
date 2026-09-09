#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool
id: fastqc
label: FastQC read quality control

doc: |
  Runs FastQC on one or more FASTQ files to produce per-read quality
  control reports. Used here as the QC step for single-cell FASTQs.

requirements:
  DockerRequirement:
    dockerPull: quay.io/biocontainers/fastqc:0.12.1--hdfd78af_0
  InlineJavascriptRequirement: {}

baseCommand: [fastqc]

inputs:
  reads:
    type: File[]
    label: Input FASTQ files
    inputBinding:
      position: 1
  threads:
    type: int
    default: 2
    inputBinding:
      prefix: --threads

arguments:
  - prefix: --outdir
    valueFrom: $(runtime.outdir)

outputs:
  html_reports:
    type: File[]
    outputBinding:
      glob: "*_fastqc.html"
  zip_reports:
    type: File[]
    outputBinding:
      glob: "*_fastqc.zip"
