rule call_peaks:
    input:
        ip_bam    = lambda wc: OUT_DIR + f"/bams/{PEAK_TO_IP[wc.peak_name]}_sub_sorted.bam",
        input_bam = lambda wc: OUT_DIR + f"/bams/{PEAK_TO_INPUT[wc.peak_name]}_dedup.bam",
    output:
        narrowpeak = OUT_DIR + "/peaks/{peak_name}_peaks.narrowPeak",
        summits    = OUT_DIR + "/peaks/{peak_name}_summits.bed",
    params:
        outdir   = OUT_DIR + "/peaks",
        fmt      = config["macs2_format"],
        qvalue   = config["macs2_qvalue"],
        mfold_lo = config["macs2_mfold_lo"],
        mfold_hi = config["macs2_mfold_hi"],
        bw       = config["macs2_bw"],
    threads: 4
    resources:
        runtime         = 60,
        mem_mb          = 51200,
        slurm_account   = config["slurm_account"],
        slurm_partition = config["slurm_partition"],
    log: OUT_DIR + "/logs/peaks_{peak_name}.log"
    shell:
        """
        module load MACS2/2.2.9.1
        macs2 callpeak -t {input.ip_bam} -c {input.input_bam} \
            -f {params.fmt} -n {wildcards.peak_name} --outdir {params.outdir} \
            --buffer-size 100000 --qvalue {params.qvalue} \
            --mfold {params.mfold_lo} {params.mfold_hi} \
            --bw {params.bw} --nomodel --keep-dup all > {log} 2>&1
        """
