// MultiQC aggregate report
// Ported from tools/multiqc.cwl (biocontainers multiqc 1.21)

process MULTIQC {
    label 'process_low'

    container 'quay.io/biocontainers/multiqc:1.21--pyhdfd78af_0'

    publishDir "${params.outdir}/multiqc", mode: 'copy'

    input:
    path qc_files, stageAs: 'qc/*'

    output:
    path "multiqc_report.html"     , emit: report
    path "multiqc_report_data"     , emit: data
    path "versions.yml"            , emit: versions

    script:
    """
    multiqc . --filename multiqc_report.html

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        multiqc: \$( multiqc --version | sed 's/^multiqc, version //' )
    END_VERSIONS
    """
}
