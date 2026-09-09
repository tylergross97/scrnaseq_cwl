// Added for the Nextflow port: builds the STAR index that the CWL took as the
// pre-built `genome_dir` input. Required because the nf-core/scrnaseq test data
// ships a FASTA + GTF rather than a pre-built index.
process STAR_GENOMEGENERATE {
    tag "${fasta.baseName}"
    label 'process_high'

    container 'quay.io/biocontainers/star:2.7.11b--h43eeafb_1'

    input:
    path fasta
    path gtf

    output:
    path 'star_index'   , emit: index
    path 'versions.yml' , emit: versions

    script:
    // For small genomes STAR requires a reduced --genomeSAindexNbases:
    // min(14, log2(genomeLength)/2 - 1). Exposed as a param (test uses 11 for chr19).
    def sa_index = params.star_genomeSAindexNbases
    """
    mkdir star_index
    STAR \\
        --runMode genomeGenerate \\
        --genomeDir star_index \\
        --genomeFastaFiles ${fasta} \\
        --sjdbGTFfile ${gtf} \\
        --runThreadN ${task.cpus} \\
        --genomeSAindexNbases ${sa_index}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        star: \$( STAR --version | sed -e 's/STAR_//g' )
    END_VERSIONS
    """

    stub:
    """
    mkdir star_index
    touch star_index/SAindex
    touch versions.yml
    """
}
