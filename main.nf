#!/usr/bin/env nextflow
// Nextflow port of scrnaseq_cwl (STARsolo mock single-cell RNA-seq pipeline)

include { STAR_GENOMEGENERATE } from './modules/local/star_genomegenerate.nf'
include { FASTQC              } from './modules/local/fastqc.nf'
include { STARSOLO            } from './modules/local/starsolo.nf'
include { MULTIQC             } from './modules/local/multiqc.nf'

workflow {
    main:
    // --- Validate required inputs ---
    if (!params.input) { error "Missing required parameter: --input <samplesheet.csv>" }
    if (!params.star_index && !(params.fasta && params.gtf)) {
        error "Provide either --star_index <dir>, or both --fasta and --gtf so the STAR index can be built."
    }

    // --- STAR index: use a pre-built one, or build it from FASTA + GTF ---
    if (params.star_index) {
        ch_genome_dir = channel.fromPath(params.star_index, checkIfExists: true).first()
    }
    else {
        STAR_GENOMEGENERATE(
            channel.fromPath(params.fasta, checkIfExists: true),
            channel.fromPath(params.gtf,   checkIfExists: true)
        )
        ch_genome_dir = STAR_GENOMEGENERATE.out.index.first()
    }

    // --- Cell barcode whitelist is optional (STARsolo falls back to 'None') ---
    ch_whitelist = params.whitelist
        ? channel.fromPath(params.whitelist, checkIfExists: true).first()
        : channel.value([])

    // --- Input contract: one row per FASTQ pair; rows sharing a sample id are lanes ---
    // Columns: sample, fastq_1 (barcode/CB+UMI, 10x R1), fastq_2 (cDNA, 10x R2)
    ch_reads = channel.fromPath(params.input, checkIfExists: true)
        | splitCsv(header: true)
        | map { row ->
            def meta = [id: row.sample]
            [meta, file(row.fastq_1, checkIfExists: true), file(row.fastq_2, checkIfExists: true)]
        }

    // --- fastqc: QC on every FASTQ pair (per lane) ---
    ch_fastqc_in = ch_reads.map { meta, barcode, cdna -> [meta, [barcode, cdna]] }
    FASTQC(ch_fastqc_in)

    // --- Group lanes belonging to the same sample for a single STARsolo run ---
    ch_samples = ch_reads
        | groupTuple()
        | map { meta, barcodes, cdnas -> [meta, barcodes, cdnas] }

    // --- star_solo: alignment + per-cell quantification per sample ---
    STARSOLO(ch_samples, ch_genome_dir, ch_whitelist)

    // --- multiqc: aggregate all FastQC zips + STAR logs into one report ---
    ch_multiqc_files = FASTQC.out.zip.map { _meta, zip -> zip }
        | mix( STARSOLO.out.log.map { _meta, log -> log } )
        | collect

    MULTIQC(ch_multiqc_files)
}
