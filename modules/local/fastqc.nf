// Ported from tools/fastqc.cwl
// FastQC read quality control on single-cell FASTQs.
process FASTQC {
    tag "${meta.id}"
    label 'process_medium'

    container 'quay.io/biocontainers/fastqc:0.12.1--hdfd78af_0'

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path('*.html'), emit: html_reports
    tuple val(meta), path('*.zip') , emit: zip_reports
    path 'versions.yml'            , emit: versions

    script:
    """
    fastqc --threads ${task.cpus} ${reads}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fastqc: \$( fastqc --version | sed -e 's/FastQC v//g' )
    END_VERSIONS
    """

    stub:
    """
    touch ${meta.id}_fastqc.html
    touch ${meta.id}_fastqc.zip
    touch versions.yml
    """
}
