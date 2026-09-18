// FastQC read quality control
// Ported from tools/fastqc.cwl (biocontainers fastqc 0.12.1)

process FASTQC {
    tag "${meta.id}"
    label 'process_low'

    container 'quay.io/biocontainers/fastqc:0.12.1--hdfd78af_0'

    publishDir "${params.outdir}/fastqc", mode: 'copy'

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*_fastqc.html"), emit: html
    tuple val(meta), path("*_fastqc.zip") , emit: zip
    path "versions.yml"                    , emit: versions

    script:
    """
    fastqc --threads ${task.cpus} ${reads}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fastqc: \$( fastqc --version | sed 's/^FastQC v//' )
    END_VERSIONS
    """
}
