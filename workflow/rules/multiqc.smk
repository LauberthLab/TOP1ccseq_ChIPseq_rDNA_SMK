rule multiqc:
    input:
        expand(OUT_DIR + "/bigwigs/{bw}.bw", bw=BW_REP_NAMES),
        expand(OUT_DIR + "/bigwigs/{bw}.bw", bw=BW_MERGED_NAMES),
        expand(OUT_DIR + "/peaks/{name}_peaks.narrowPeak", name=PEAK_NAMES),
        OUT_DIR + "/counts/raw_counts_TOP1cc_all.txt",
    output:
        OUT_DIR + "/multiqc_report/multiqc_report.html",
    params:
        scan_dir   = OUT_DIR,
        report_dir = OUT_DIR + "/multiqc_report",
    threads: 4
    resources:
        runtime         = 30,
        mem_mb          = 16384,
        slurm_account   = config["slurm_account"],
        slurm_partition = config["slurm_partition"],
    log: OUT_DIR + "/logs/multiqc.log"
    shell:
        """
        module load multiqc
        multiqc {params.scan_dir} -o {params.report_dir} --force > {log} 2>&1
        """
