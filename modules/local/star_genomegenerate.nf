// Build a STAR genome index from a FASTA + GTF (used when --star_index is not provided)
process STAR_GENOMEGENERATE {
    tag "${fasta.baseName}"
    label 'process_high'
    container 'quay.io/biocontainers/star:2.7.11b--h43eeafb_1'

    input:
    path fasta
    path gtf

    output:
    path "star_index"  , emit: index
    path "versions.yml", emit: versions

    script:
    def args = task.ext.args ?: ''
    """
    mkdir -p star_index
    STAR \\
        --runMode genomeGenerate \\
        --genomeDir star_index \\
        --genomeFastaFiles ${fasta} \\
        --sjdbGTFfile ${gtf} \\
        --runThreadN ${task.cpus} \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        star: \$( STAR --version )
    END_VERSIONS
    """

    stub:
    """
    mkdir -p star_index
    touch star_index/SA
    touch versions.yml
    """
}
