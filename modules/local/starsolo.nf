// Port of tools/star_solo.cwl — STARsolo alignment + per-cell quantification
process STARSOLO {
    tag "${meta.id}"
    label 'process_high'
    container 'quay.io/biocontainers/star:2.7.11b--h43eeafb_1'

    input:
    tuple val(meta), path(barcode_reads), path(cdna_reads)
    path genome_dir
    path whitelist   // optional: pass [] to let STARsolo run without a predefined whitelist

    output:
    tuple val(meta), path("*Aligned.sortedByCoord.out.bam"), emit: bam
    tuple val(meta), path("*Solo.out")                     , emit: matrix
    tuple val(meta), path("*Log.final.out")                , emit: log
    path "versions.yml"                                    , emit: versions

    script:
    def args   = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def whitelist_arg = whitelist ? "${whitelist}" : 'None'
    // STARsolo takes comma-separated read files when a sample spans multiple lanes
    def cdna    = (cdna_reads    instanceof List ? cdna_reads    : [cdna_reads]).join(',')
    def barcode = (barcode_reads instanceof List ? barcode_reads : [barcode_reads]).join(',')
    // STARsolo convention: --readFilesIn <cDNA> <barcode>  (10x R2 then R1)
    """
    STAR \\
        --genomeDir ${genome_dir} \\
        --soloCBwhitelist ${whitelist_arg} \\
        --runThreadN ${task.cpus} \\
        --outFileNamePrefix ${prefix}_ \\
        --soloType CB_UMI_Simple \\
        --readFilesIn ${cdna} ${barcode} \\
        --readFilesCommand zcat \\
        --outSAMtype BAM SortedByCoordinate \\
        --soloFeatures Gene \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        star: \$( STAR --version )
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_Aligned.sortedByCoord.out.bam
    mkdir -p ${prefix}_Solo.out
    touch ${prefix}_Log.final.out
    touch versions.yml
    """
}
