rule align_genome:
    input:
        r1 = OUT_DIR + "/trimmed/{sample}_val_1.fq.gz",
        r2 = OUT_DIR + "/trimmed/{sample}_val_2.fq.gz",
    output:
        bam = OUT_DIR + "/bams/{sample}_dedup.bam",
        bai = OUT_DIR + "/bams/{sample}_dedup.bam.bai",
    params:
        index   = config["genome_index"],
        mapq    = config["mapq"],
        bam_dir = OUT_DIR + "/bams",
    threads: config["threads"]
    resources:
        runtime         = 180,
        mem_mb          = 61440,
        slurm_account   = config["slurm_account"],
        slurm_partition = config["slurm_partition"],
    log: OUT_DIR + "/logs/align_genome_{sample}.log"
    shell:
        """
        module load bowtie2
        module load samtools
        bowtie2 -p {threads} -x {params.index} -1 {input.r1} -2 {input.r2} \
            -S {params.bam_dir}/{wildcards.sample}.sam > {log} 2>&1
        samtools view -@ {threads} -q {params.mapq} -b \
            -o {params.bam_dir}/{wildcards.sample}_filt.bam \
            {params.bam_dir}/{wildcards.sample}.sam >> {log} 2>&1
        rm {params.bam_dir}/{wildcards.sample}.sam
        samtools fixmate -@ {threads} -m \
            {params.bam_dir}/{wildcards.sample}_filt.bam \
            {params.bam_dir}/{wildcards.sample}_fixmate.bam >> {log} 2>&1
        rm {params.bam_dir}/{wildcards.sample}_filt.bam
        samtools sort -@ {threads} \
            -o {params.bam_dir}/{wildcards.sample}_sorted.bam \
            {params.bam_dir}/{wildcards.sample}_fixmate.bam >> {log} 2>&1
        rm {params.bam_dir}/{wildcards.sample}_fixmate.bam
        samtools markdup -@ {threads} -s \
            {params.bam_dir}/{wildcards.sample}_sorted.bam \
            {output.bam} >> {log} 2>&1
        rm {params.bam_dir}/{wildcards.sample}_sorted.bam
        samtools index -@ {threads} {output.bam} >> {log} 2>&1
        """
