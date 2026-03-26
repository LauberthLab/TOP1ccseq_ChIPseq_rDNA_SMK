rule downsample:
    input:
        bam      = OUT_DIR + "/bams/{ip_sample}_dedup.bam",
        bai      = OUT_DIR + "/bams/{ip_sample}_dedup.bam.bai",
        norm_tsv = OUT_DIR + "/norm/spike_norm_factors.tsv",
    output:
        bam = OUT_DIR + "/bams/{ip_sample}_sub_sorted.bam",
        bai = OUT_DIR + "/bams/{ip_sample}_sub_sorted.bam.bai",
    threads: config["threads"]
    resources:
        runtime         = 120,
        mem_mb          = 61440,
        slurm_account   = config["slurm_account"],
        slurm_partition = config["slurm_partition"],
    log: OUT_DIR + "/logs/downsample_{ip_sample}.log"
    shell:
        """
        module load samtools
        FRAC=$(awk -v sid="{wildcards.ip_sample}" \
            'BEGIN{{FS="\t"}} $1==sid {{print $3}}' {input.norm_tsv})
        if [[ -z "$FRAC" ]]; then echo "ERROR: no factor for {wildcards.ip_sample}"; exit 1; fi
        IS_ONE=$(echo "${{FRAC}} >= 1.0" | bc -l)
        if [[ "${{IS_ONE}}" -eq 1 ]]; then
            ln -sf "$(realpath {input.bam})" {output.bam}
            ln -sf "$(realpath {input.bai})" {output.bai}
        else
            SUB_BAM="$(dirname {output.bam})/{wildcards.ip_sample}_sub.bam"
            samtools view -b -@ {threads} -s "$FRAC" -o "$SUB_BAM" {input.bam} >> {log} 2>&1
            samtools sort -@ {threads} -o {output.bam} "$SUB_BAM" >> {log} 2>&1
            rm "$SUB_BAM"
            samtools index -@ {threads} {output.bam} >> {log} 2>&1
        fi
        """
