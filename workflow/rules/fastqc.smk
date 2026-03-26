rule fastqc:
    input:
        r1 = lambda wc: config["fastq_dir"] + f"/{FASTQ_PREFIX[wc.sample]}_R1_001.fastq.gz",
        r2 = lambda wc: config["fastq_dir"] + f"/{FASTQ_PREFIX[wc.sample]}_R2_001.fastq.gz",
    output:
        html_r1 = OUT_DIR + "/fastqc/{sample}_R1_001_fastqc.html",
        html_r2 = OUT_DIR + "/fastqc/{sample}_R2_001_fastqc.html",
    params:
        outdir       = OUT_DIR + "/fastqc",
        fastq_screen = config["fastq_screen"],
    threads: 8
    resources:
        runtime         = 120,
        mem_mb          = 51200,
        slurm_account   = config["slurm_account"],
        slurm_partition = config["slurm_partition"],
    log: OUT_DIR + "/logs/fastqc_{sample}.log"
    shell:
        """
        module load fastqc
        fastqc {input.r1} {input.r2} -t {threads} -o {params.outdir} > {log} 2>&1
        if [[ -x "{params.fastq_screen}" ]]; then
            "{params.fastq_screen}" {input.r1} {input.r2} \
                --aligner BOWTIE2 --threads {threads} \
                --outdir {params.outdir} >> {log} 2>&1
        fi
        """
