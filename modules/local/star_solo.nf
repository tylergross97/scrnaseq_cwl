// STARsolo single-cell alignment and quantification
// Ported from tools/star_solo.cwl (biocontainers star 2.7.11b)
//
// STARsolo --readFilesIn order is <cDNA> <barcode>, i.e. 10x R2 then R1.
// Per-sample tool knobs (--soloCBlen, --soloUMIlen) are supplied via
// task.ext.args from conf/modules.config, so this module never reads params.

process STAR_SOLO {
    tag "${meta.id}"
    label 'process_high'

    container 'quay.io/biocontainers/star:2.7.11b--h43eeafb_1'

    publishDir "${params.outdir}/star_solo", mode: 'copy'

    input:
    tuple val(meta), path(cdna_reads), path(barcode_reads)
    path genome_dir
    path whitelist

    output:
    tuple val(meta), path("*Aligned.sortedByCoord.out.bam"), emit: bam
    tuple val(meta), path("*Solo.out")                     , emit: matrix
    tuple val(meta), path("*Log.final.out")                , emit: log
    path "versions.yml"                                    , emit: versions

    script:
    def args   = task.ext.args   ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    STAR \\
        --genomeDir ${genome_dir} \\
        --soloType CB_UMI_Simple \\
        --soloCBwhitelist ${whitelist} \\
        --readFilesIn ${cdna_reads} ${barcode_reads} \\
        --readFilesCommand zcat \\
        --runThreadN ${task.cpus} \\
        --outSAMtype BAM SortedByCoordinate \\
        --soloFeatures Gene \\
        --outFileNamePrefix ${prefix}_ \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        star: \$( STAR --version )
    END_VERSIONS
    """
}
