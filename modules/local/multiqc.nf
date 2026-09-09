// Ported from tools/multiqc.cwl
// Aggregates FastQC zips + STAR logs into a single HTML report.
process MULTIQC {
    label 'process_single'

    container 'quay.io/biocontainers/multiqc:1.21--pyhdfd78af_0'

    input:
    path qc_files, stageAs: 'qc/*'

    output:
    path 'multiqc_report.html'     , emit: report
    path 'multiqc_report_data'     , emit: data_dir
    path 'versions.yml'            , emit: versions

    script:
    """
    multiqc . --filename multiqc_report.html

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        multiqc: \$( multiqc --version | sed -e 's/multiqc, version //g' )
    END_VERSIONS
    """

    stub:
    """
    touch multiqc_report.html
    mkdir multiqc_report_data
    touch versions.yml
    """
}
