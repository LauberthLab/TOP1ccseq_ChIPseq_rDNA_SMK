rule normalize:
    input:
        spike_bams = expand(OUT_DIR + "/spike/{sid}_spike.bam", sid=IP_SAMPLES),
    output:
        OUT_DIR + "/norm/spike_norm_factors.tsv",
    threads: config["threads"]
    resources:
        runtime         = 30,
        mem_mb          = 20480,
        slurm_account   = config["slurm_account"],
        slurm_partition = config["slurm_partition"],
    log: OUT_DIR + "/logs/normalize.log"
    shell:
        """
        module load samtools
        declare -a SIDS
        declare -a RATIOS
        for BAM in {input.spike_bams}; do
            SID=$(basename "$BAM" _spike.bam)
            total=$(samtools view -@ {threads} -c "$BAM")
            filtered=$(samtools view -@ {threads} -c -F 1284 "$BAM")
            if [[ "$total" -eq 0 ]]; then
                echo "WARNING: $SID has 0 spike-in reads" | tee -a {log}; continue
            fi
            ratio=$(echo "scale=5; ${{filtered}} / ${{total}}" | bc -l)
            SIDS+=("$SID"); RATIOS+=("$ratio")
        done
        min_ratio=$(printf '%s\n' "${{RATIOS[@]}}" | sort -g | head -n 1)
        echo -e "sample_id\tspike_ratio\tnorm_factor" > {output}
        for j in "${{!SIDS[@]}}"; do
            norm=$(echo "scale=5; ${{min_ratio}} / ${{RATIOS[$j]}}" | bc -l)
            echo -e "${{SIDS[$j]}}\t${{RATIOS[$j]}}\t${{norm}}" >> {output}
        done
        cat {output} | tee -a {log}
        """
