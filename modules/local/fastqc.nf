// Port of tools/fastqc.cwl — FastQC read quality control
process FASTQC {
    tag "${meta.id}"
    label 'process_low'
    container 'quay.io/biocontainers/fastqc:0.12.1--hdfd78af_0'

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*_fastqc.html"), emit: html
    tuple val(meta), path("*_fastqc.zip") , emit: zip
    path "versions.yml"                    , emit: versions

    script:
    def args = task.ext.args ?: ''
    """
    fastqc --threads ${task.cpus} ${args} ${reads}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fastqc: \$( fastqc --version | sed 's/FastQC v//' )
    END_VERSIONS
    """

    stub:
    def reads_list = reads instanceof List ? reads : [reads]
    def touches = reads_list.collect { r ->
        def base = r.name.replaceAll(/\.(fastq|fq)(\.gz)?$/, '')
        "touch ${base}_fastqc.html ${base}_fastqc.zip"
    }.join('\n    ')
    """
    ${touches}
    touch versions.yml
    """
}
