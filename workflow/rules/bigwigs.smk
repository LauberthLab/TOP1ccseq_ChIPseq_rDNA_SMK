def _group_input_bams(group):
    seen = {}
    for s in GROUPS[group]:
        inp = IP_TO_INPUT[s]
        seen[inp] = OUT_DIR + f"/bams/{inp}_dedup.bam"
    return list(seen.values())

def _group_input_bais(group):
    return [b + ".bai" for b in _group_input_bams(group)]

rule bigwig_rep:
    input:
        ip_bam    = lambda wc: OUT_DIR + f"/bams/{BW_TO_IP[wc.bw_name]}_sub_sorted.bam",
        ip_bai    = lambda wc: OUT_DIR + f"/bams/{BW_TO_IP[wc.bw_name]}_sub_sorted.bam.bai",
        input_bam = lambda wc: OUT_DIR + f"/bams/{BW_TO_INPUT[wc.bw_name]}_dedup.bam",
        input_bai = lambda wc: OUT_DIR + f"/bams/{BW_TO_INPUT[wc.bw_name]}_dedup.bam.bai",
    output:
        OUT_DIR + "/bigwigs/{bw_name}.bw",
    params:
        normalize   = config["bw_normalize"],
        pseudocount = config["bw_pseudocount"],
        bin_size    = config["bin_size"],
    threads: config["threads"]
    resources:
        runtime         = 120,
        mem_mb          = 51200,
        slurm_account   = config["slurm_account"],
        slurm_partition = config["slurm_partition"],
    log: OUT_DIR + "/logs/bigwig_rep_{bw_name}.log"
    shell:
        """
        module load deeptools
        bamCompare -b1 {input.ip_bam} -b2 {input.input_bam} -o {output} \
            -p max --normalizeUsing {params.normalize} \
            --scaleFactorsMethod None --pseudocount {params.pseudocount} \
            -bs {params.bin_size} > {log} 2>&1
        """

rule bigwig_merged:
    input:
        ip_bams    = lambda wc: expand(OUT_DIR + "/bams/{s}_sub_sorted.bam", s=GROUPS[wc.group]),
        ip_bais    = lambda wc: expand(OUT_DIR + "/bams/{s}_sub_sorted.bam.bai", s=GROUPS[wc.group]),
        input_bams = lambda wc: _group_input_bams(wc.group),
        input_bais = lambda wc: _group_input_bais(wc.group),
    output:
        merged_ip_bam    = OUT_DIR + "/bams/{group}_IP_merged.bam",
        merged_ip_bai    = OUT_DIR + "/bams/{group}_IP_merged.bam.bai",
        merged_input_bam = OUT_DIR + "/bams/{group}_Input_merged.bam",
        merged_input_bai = OUT_DIR + "/bams/{group}_Input_merged.bam.bai",
        bw               = OUT_DIR + "/bigwigs/{group}_log2_merged_wrDNA.bw",
    params:
        normalize   = config["bw_normalize"],
        pseudocount = config["bw_pseudocount"],
        bin_size    = config["bin_size"],
    threads: config["threads"]
    resources:
        runtime         = 120,
        mem_mb          = 51200,
        slurm_account   = config["slurm_account"],
        slurm_partition = config["slurm_partition"],
    log: OUT_DIR + "/logs/bigwig_merged_{group}.log"
    shell:
        """
        module load samtools deeptools
        samtools merge -@ {threads} -f {output.merged_ip_bam} {input.ip_bams} > {log} 2>&1
        samtools index -@ {threads} {output.merged_ip_bam} >> {log} 2>&1
        samtools merge -@ {threads} -f {output.merged_input_bam} {input.input_bams} >> {log} 2>&1
        samtools index -@ {threads} {output.merged_input_bam} >> {log} 2>&1
        bamCompare -b1 {output.merged_ip_bam} -b2 {output.merged_input_bam} -o {output.bw} \
            -p max --normalizeUsing {params.normalize} \
            --scaleFactorsMethod None --pseudocount {params.pseudocount} \
            -bs {params.bin_size} >> {log} 2>&1
        """
