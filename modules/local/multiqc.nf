// Port of tools/multiqc.cwl — aggregate QC/alignment logs into one HTML report
process MULTIQC {
    label 'process_low'
    container 'quay.io/biocontainers/multiqc:1.21--pyhdfd78af_0'

    input:
    path qc_files, stageAs: '?/*'

    output:
    path "multiqc_report.html"     , emit: report
    path "multiqc_report_data"     , emit: data
    path "versions.yml"            , emit: versions

    script:
    def args = task.ext.args ?: ''
    """
    multiqc . --filename multiqc_report.html ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        multiqc: \$( multiqc --version | sed 's/multiqc, version //' )
    END_VERSIONS
    """

    stub:
    """
    touch multiqc_report.html
    mkdir -p multiqc_report_data
    touch versions.yml
    """
}
