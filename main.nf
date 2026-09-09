#!/usr/bin/env nextflow
/*
 * Mock single-cell RNA-seq pipeline (STARsolo)
 * Converted from scrnaseq.cwl (CWL v1.2) to Nextflow DSL2.
 *
 *   1. FASTQC              - QC on the cDNA and barcode FASTQs
 *   2. STAR_GENOMEGENERATE - build STAR index from FASTA + GTF (see note below)
 *   3. STAR_SOLO           - STARsolo alignment + per-cell gene quantification
 *   4. MULTIQC             - aggregate FastQC + STAR logs into one report
 *
 * Note: the original CWL took a pre-built STAR index (`genome_dir`). This port
 * builds the index from `fasta` + `gtf` so it runs on the nf-core/scrnaseq
 * test data (which ships references, not a pre-built index).
 */

include { FASTQC              } from './modules/local/fastqc.nf'
include { STAR_GENOMEGENERATE } from './modules/local/star_genomegenerate.nf'
include { STAR_SOLO           } from './modules/local/star_solo.nf'
include { MULTIQC             } from './modules/local/multiqc.nf'

workflow {
    // ----- Reference channels -----
    ch_fasta = channel.fromPath(params.fasta, checkIfExists: true)
    ch_gtf   = channel.fromPath(params.gtf,   checkIfExists: true)

    def whitelist_file = params.whitelist
        ? file(params.whitelist, checkIfExists: true)
        : file("${projectDir}/assets/NO_FILE")

    // ----- Read samplesheet: sample, fastq_1 (R1/barcode), fastq_2 (R2/cDNA) -----
    ch_reads = channel.fromPath(params.input, checkIfExists: true)
        .splitCsv(header: true)
        .map { row ->
            def meta = [
                id     : row.sample,
                cb_len : params.cb_len,
                umi_len: params.umi_len,
            ]
            [ meta, [ file(row.fastq_1, checkIfExists: true), file(row.fastq_2, checkIfExists: true) ] ]
        }
        // Merge multiple lanes belonging to the same sample.
        .groupTuple()
        .map { meta, read_pairs -> [ meta, read_pairs.flatten() ] }

    // ----- 1. FastQC -----
    FASTQC(ch_reads)

    // ----- 2. Build STAR index (reusable value channel) -----
    STAR_GENOMEGENERATE(ch_fasta, ch_gtf)

    // ----- 3. STARsolo -----
    STAR_SOLO(
        ch_reads,
        STAR_GENOMEGENERATE.out.index.first(),
        whitelist_file,
    )

    // ----- 4. MultiQC over FastQC zips + STAR logs -----
    ch_multiqc_files = FASTQC.out.zip_reports.map { _meta, zips -> zips }
        .mix(STAR_SOLO.out.log_final.map { _meta, log -> log })
        .collect()

    MULTIQC(ch_multiqc_files)
}
