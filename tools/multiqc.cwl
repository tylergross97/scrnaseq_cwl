#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool
id: multiqc
label: MultiQC aggregate report

doc: |
  Aggregates QC and alignment logs (FastQC zips, STAR logs) into a single
  interactive HTML report.

requirements:
  DockerRequirement:
    dockerPull: quay.io/biocontainers/multiqc:1.21--pyhdfd78af_0
  InitialWorkDirRequirement:
    listing: $(inputs.qc_files)
  InlineJavascriptRequirement: {}

baseCommand: [multiqc]

inputs:
  qc_files:
    type: File[]
    label: QC/log files to aggregate

arguments:
  - valueFrom: "."
    position: 1
  - prefix: --outdir
    valueFrom: $(runtime.outdir)
  - prefix: --filename
    valueFrom: multiqc_report.html

outputs:
  report:
    type: File
    outputBinding:
      glob: multiqc_report.html
  data_dir:
    type: Directory
    outputBinding:
      glob: multiqc_report_data
