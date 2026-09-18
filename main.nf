#!/usr/bin/env nextflow

// scrnaseq — mock single-cell RNA-seq pipeline (STARsolo)
// Nextflow DSL2 port of scrnaseq.cwl
//
//   1. FASTQC     - QC on the cDNA and barcode FASTQs
//   2. STAR_SOLO  - STARsolo alignment + per-cell gene quantification
//   3. MULTIQC    - aggregate FastQC + STAR logs into one report

include { FASTQC    } from './modules/local/fastqc.nf'
include { STAR_SOLO } from './modules/local/star_solo.nf'
include { MULTIQC   } from './modules/local/multiqc.nf'

workflow {
    // Samplesheet: one row per sample -> (meta, cDNA FASTQ, barcode FASTQ)
    ch_samples = channel.fromPath(params.input)
        .splitCsv(header: true)
        .map { row ->
            def meta = [id: row.sample]
            tuple(meta, file(row.cdna_reads), file(row.barcode_reads))
        }

    // Shared reference inputs — value channels so they are reused across samples
    ch_genome_dir = channel.value(file(params.genome_dir))
    ch_whitelist  = channel.value(file(params.whitelist))

    // 1. FastQC on both FASTQs per sample
    ch_fastqc_in = ch_samples.map { meta, cdna, barcode ->
        tuple(meta, [cdna, barcode])
    }
    FASTQC(ch_fastqc_in)

    // 2. STARsolo alignment + quantification
    STAR_SOLO(ch_samples, ch_genome_dir, ch_whitelist)

    // 3. Aggregate FastQC zips + STAR logs into one MultiQC report
    ch_multiqc_files = FASTQC.out.zip.map { _meta, zips -> zips }
        .mix( STAR_SOLO.out.log.map { _meta, log -> log } )
        .flatten()
        .collect()
    MULTIQC(ch_multiqc_files)
}
