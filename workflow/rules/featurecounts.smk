rule featurecounts:
    input:
        ip_bams    = expand(OUT_DIR + "/bams/{s}_sub_sorted.bam", s=IP_SAMPLES),
        input_bams = expand(OUT_DIR + "/bams/{s}_dedup.bam", s=INPUT_SAMPLES),
        gtf        = config["gtf"],
    output:
        OUT_DIR + "/counts/raw_counts_TOP1cc_all.txt",
    params:
        feature      = config["fc_feature"],
        attribute    = config["fc_attribute"],
        strandedness = config["fc_strandedness"],
    threads: 20
    resources:
        runtime         = 60,
        mem_mb          = 71680,
        slurm_account   = config["slurm_account"],
        slurm_partition = config["slurm_partition"],
    log: OUT_DIR + "/logs/featurecounts.log"
    shell:
        """
        module load subread
        featureCounts -T {threads} -t {params.feature} -g {params.attribute} \
            -F GTF -s {params.strandedness} -p \
            -a {input.gtf} -o {output} \
            {input.ip_bams} {input.input_bams} > {log} 2>&1
        """
