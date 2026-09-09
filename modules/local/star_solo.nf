// Ported from tools/star_solo.cwl
// STARsolo alignment + per-cell gene quantification.
// STARsolo --readFilesIn order is <cDNA> <barcode>, i.e. R2 then R1.
// Whitelist is optional: falls back to `--soloCBwhitelist None` when absent.
process STAR_SOLO {
    tag "${meta.id}"
    label 'process_high'

    container 'quay.io/biocontainers/star:2.7.11b--h43eeafb_1'

    input:
    tuple val(meta), path(reads)
    path index
    path whitelist

    output:
    tuple val(meta), path('*Aligned.sortedByCoord.out.bam'), emit: bam
    tuple val(meta), path('*Solo.out')                     , emit: solo_matrix
    tuple val(meta), path('*Log.final.out')                , emit: log_final
    path 'versions.yml'                                    , emit: versions

    script:
    def prefix   = "${meta.id}_"
    // reads arrive flat as [R1, R2] (optionally repeated per lane).
    // forward = barcode reads (R1), reverse = cDNA reads (R2).
    def (forward, reverse) = reads.collate(2).transpose()
    def cdna     = reverse.join(',')
    def barcode  = forward.join(',')
    def wl_arg   = whitelist.name != 'NO_FILE' ? "--soloCBwhitelist ${whitelist}" : "--soloCBwhitelist None"
    """
    STAR \\
        --genomeDir ${index} \\
        --readFilesIn ${cdna} ${barcode} \\
        --readFilesCommand zcat \\
        --runThreadN ${task.cpus} \\
        --outFileNamePrefix ${prefix} \\
        --soloType CB_UMI_Simple \\
        --soloCBlen ${meta.cb_len} \\
        --soloUMIlen ${meta.umi_len} \\
        ${wl_arg} \\
        --soloFeatures Gene \\
        --outSAMtype BAM SortedByCoordinate

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        star: \$( STAR --version | sed -e 's/STAR_//g' )
    END_VERSIONS
    """

    stub:
    def prefix = "${meta.id}_"
    """
    touch ${prefix}Aligned.sortedByCoord.out.bam
    mkdir -p ${prefix}Solo.out/Gene
    touch ${prefix}Log.final.out
    touch versions.yml
    """
}
