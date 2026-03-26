rule trim:
    input:
        r1 = lambda wc: config["fastq_dir"] + f"/{FASTQ_PREFIX[wc.sample]}_R1_001.fastq.gz",
        r2 = lambda wc: config["fastq_dir"] + f"/{FASTQ_PREFIX[wc.sample]}_R2_001.fastq.gz",
    output:
        r1 = OUT_DIR + "/trimmed/{sample}_val_1.fq.gz",
        r2 = OUT_DIR + "/trimmed/{sample}_val_2.fq.gz",
    params:
        outdir  = OUT_DIR + "/trimmed",
        quality = config["trim_quality"],
    threads: 8
    resources:
        runtime         = 120,
        mem_mb          = 51200,
        slurm_account   = config["slurm_account"],
        slurm_partition = config["slurm_partition"],
    log: OUT_DIR + "/logs/trim_{sample}.log"
    shell:
        """
        module load TrimGalore
        module load cutadapt/4.2
        trim_galore --illumina -j {threads} --paired -q {params.quality} \
            --basename {wildcards.sample} {input.r1} {input.r2} \
            -o {params.outdir} > {log} 2>&1
        """
