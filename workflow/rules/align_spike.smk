rule align_spike:
    input:
        r1 = OUT_DIR + "/trimmed/{ip_sample}_val_1.fq.gz",
        r2 = OUT_DIR + "/trimmed/{ip_sample}_val_2.fq.gz",
    output:
        bam = OUT_DIR + "/spike/{ip_sample}_spike.bam",
    params:
        index     = config["spike_index"],
        spike_dir = OUT_DIR + "/spike",
    threads: config["threads"]
    resources:
        runtime         = 240,
        mem_mb          = 51200,
        slurm_account   = config["slurm_account"],
        slurm_partition = config["slurm_partition"],
    log: OUT_DIR + "/logs/align_spike_{ip_sample}.log"
    shell:
        """
        module load bowtie2
        module load samtools
        bowtie2 -p {threads} -x {params.index} -1 {input.r1} -2 {input.r2} \
            -S {params.spike_dir}/{wildcards.ip_sample}_spike.sam > {log} 2>&1
        samtools view -@ {threads} -b \
            -o {output.bam} \
            {params.spike_dir}/{wildcards.ip_sample}_spike.sam >> {log} 2>&1
        rm {params.spike_dir}/{wildcards.ip_sample}_spike.sam
        """
