# TOP1cc ChIP-seq Snakemake Pipeline

A Snakemake pipeline for processing TOP1 cleavage complex (TOP1cc) ChIP-seq data with *Drosophila* spike-in normalization, designed for the Northwestern Quest HPC cluster (SLURM).

---

## Pipeline overview

Paired-end ChIP-seq reads are processed through adapter trimming, genome alignment (hg38 + rDNA), spike-in alignment (dm6/BDGP6), spike-in normalization via downsampling, log2 IP/Input bigWig generation (per-replicate and merged), MACS2 peak calling, gene-level feature counting, and MultiQC report aggregation.

```
raw FASTQs
    │
    ├── trim (Trim Galore)
    │       │
    │       ├── align_genome (Bowtie2 → hg38+rDNA, dedup via samtools)
    │       │       │
    │       │       ├── align_spike (Bowtie2 → dm6/BDGP6)
    │       │       │       │
    │       │       │       └── normalize (spike-in ratio → norm factors)
    │       │       │               │
    │       │       └── downsample (subsample IP BAMs by norm factor)
    │       │               │
    │       │               ├── bigwig_rep (bamCompare, per-replicate log2)
    │       │               ├── bigwig_merged (merge reps → bamCompare)
    │       │               ├── call_peaks (MACS2 narrowPeak)
    │       │               └── featurecounts (Subread)
    │       │
    │       └── fastqc (raw read QC)
    │
    └── multiqc (aggregate all QC reports)
```


---

## Directory structure

```
TOP1cc_ChIPseq_smk/
├── config/
│   └── config.yaml              # Pipeline parameters, paths, tool settings
├── profiles/
│   └── slurm/
│       ├── config.yaml          # SLURM cluster submission settings
│       └── status.sh            # Job status polling script for Snakemake
├── workflow/
│   ├── Snakefile                # Main entry point: reads metadata, defines targets
│   └── rules/
│       ├── trim.smk             # Adapter/quality trimming (Trim Galore + cutadapt)
│       ├── fastqc.smk           # Read-level QC (FastQC)
│       ├── align_genome.smk     # Alignment to hg38+rDNA (Bowtie2), filtering, dedup
│       ├── align_spike.smk      # Alignment to dm6 spike-in genome (Bowtie2)
│       ├── normalize.smk        # Compute spike-in normalization factors
│       ├── downsample.smk       # Downsample IP BAMs by spike-in norm factor
│       ├── bigwigs.smk          # log2(IP/Input) bigWigs: per-rep and merged (deepTools)
│       ├── featurecounts.smk    # Gene-level read counts (Subread featureCounts)
│       ├── peaks.smk            # Peak calling (MACS2, narrowPeak mode)
│       └── multiqc.smk          # Aggregate QC report (MultiQC)
├── OUTPUT_DIR/                  # All pipeline outputs (not tracked in git)
│   ├── metadata.tsv             # Sample sheet , you can store it anywhere else as well
│   └── all_pipeline_outputs/
│       └── pipeline_out/
│           ├── trimmed/
│           ├── bams/
│           ├── spike/
│           ├── norm/
│           ├── bigwigs/
│           ├── peaks/
│           ├── counts/
│           ├── multiqc_report/
│           └── logs/
├── .gitignore
├── environment.yaml             # Conda/mamba env for running Snakemake
└── README.md
```

> **Note:** Consider moving `metadata.tsv` into `config/` alongside `config.yaml` — the sample sheet is a configuration input, not a pipeline output.

---

## Setup

### 1. Install Snakemake

> **Important:** Do not use `module load snakemake` on Quest. The Quest module wraps Snakemake inside a Singularity container that cannot access SLURM binaries (`sbatch`, `sacct`), causing all cluster submissions to fail with exit code 127.

Create the environment from the provided `environment.yaml`:

```bash
mamba env create -f environment.yaml
conda activate snake

# Verify — should show a real path, NOT a shell function
which snakemake
snakemake --version
```

If `mamba` is not available, `conda env create -f environment.yaml` works as well (just slower).

If `which snakemake` still shows a shell function from your `.bashrc`, run `unset -f snakemake` or start a new shell after commenting out the function definition.

### 2. Clone the repository

```bash
cd /projects/b1042/LauberthLab/snakemake_pipelines
git clone https://github.com/LauberthLab/TOP1cc_ChIPseq_smk.git
cd TOP1cc_ChIPseq_smk
```

### 3. Configure paths

Edit `config/config.yaml` to set paths appropriate for your data:

```yaml
fastq_dir:     "/path/to/your/FASTQ/directory"
out_dir:       "/path/to/desired/output/directory"
metadata:      "/path/to/metadata.tsv"
genome_index:  "/path/to/hg38_rDNA_bowtie2_index"
spike_index:   "/path/to/BDGP6_bowtie2_index"
gtf:           "/path/to/hg38_rDNA_annotation.gtf"
```

### 4. Prepare the sample sheet

Create or edit the metadata TSV referenced in `config/config.yaml`. The file must be tab-separated with the following columns:

| Column | Description |
|--------|-------------|
| `sample_id` | Unique sample name used throughout the pipeline |
| `fastq_prefix` | FASTQ filename prefix (up to `_R1_001.fastq.gz`) |
| `type` | `IP` or `Input` |
| `condition` | Treatment condition (e.g., `DMSO`, `ISD`) |
| `timepoint` | Time point (e.g., `6h`, `24h`) |
| `replicate` | Replicate number (integer) |
| `input_for` | For IP samples: `sample_id` of the matched Input. Blank for Inputs. |

Example:

```
sample_id            fastq_prefix                type    condition  timepoint  replicate  input_for
DMSO_6h_IP_rep1      21161D-76-01_S152_L005      IP      DMSO       6h         1          DMSO_6h_Input_rep1
DMSO_6h_Input_rep1   21161D-76-09_S160_L005      Input   DMSO       6h         1
```

Lines starting with `#` are ignored.

---

## Running the pipeline

### Dry run (recommended first)

```bash
conda activate snakemake
cd /projects/b1042/LauberthLab/snakemake_pipelines/TOP1cc_ChIPseq_smk

snakemake --profile profiles/slurm -n
```

### Full run

```bash
snakemake --profile profiles/slurm --jobs 50
```

This submits up to 50 concurrent SLURM jobs. The profile handles all `sbatch` arguments, resource allocation, and job status polling.

### Useful commands

```bash
# Resume after failure (automatically skips completed steps)
snakemake --profile profiles/slurm --jobs 50

# Force re-run of a specific rule
snakemake --profile profiles/slurm --jobs 50 --forcerun trim

# Unlock after a crashed run
snakemake --unlock

# Generate a DAG visualization
snakemake --dag | dot -Tpng > dag.png
```

---

## SLURM profile

The file `profiles/slurm/config.yaml` controls cluster submission. Key details:

- **`runtime`** is specified in **integer minutes** (Snakemake 7 requirement). Use `120` not `"02:00:00"`.
- **`-o` / `-e`** short flags are used instead of `--output` / `--error` to avoid an argparse collision with Snakemake's `--output-wait` flag.
- **`--parsable`** ensures `sbatch` returns only the numeric job ID for status tracking.
- **`status.sh`** translates uppercase SLURM states (`RUNNING`, `COMPLETED`, `FAILED`) to the lowercase tokens Snakemake expects (`running`, `success`, `failed`), and treats empty responses (race condition on newly submitted jobs) as `running`.

---

## Output files

| Directory          | Contents                                                       |
|--------------------|----------------------------------------------------------------|
| `trimmed/`         | Adapter-trimmed FASTQs and trimming reports                    |
| `bams/`            | Deduplicated BAMs, spike-in-normalized (downsampled) BAMs, merged BAMs |
| `spike/`           | Spike-in (dm6) alignment BAMs                                  |
| `norm/`            | `spike_norm_factors.tsv` with per-sample normalization factors  |
| `bigwigs/`         | log2(IP/Input) bigWigs: per-replicate and condition-merged      |
| `peaks/`           | MACS2 narrowPeak and summit BED files                          |
| `counts/`          | featureCounts raw count matrix                                  |
| `multiqc_report/`  | Aggregated MultiQC HTML report                                  |
| `logs/`            | Per-rule SLURM stdout/stderr log files                          |

---

## Reference genomes

| Resource | Description | Path on Quest |
|----------|-------------|---------------|
| Genome index | hg38 + rDNA (KY962518.1) Bowtie2 index | `/projects/b1042/LauberthLab/indices/hg38_rDNA_v1.0` |
| Spike-in index | dm6 / BDGP6 Bowtie2 index | `/projects/b1042/LauberthLab/Genome/BDGP6/BDGP6` |
| GTF | hg38 + rDNA gene annotation | See `config/config.yaml` |

---

## Quest module dependencies

The pipeline loads the following tools via `module load` within each SLURM job:

| Rule | Modules |
|------|---------|
| trim | `TrimGalore`, `cutadapt/4.2` |
| align_genome, align_spike | `bowtie2`, `samtools` |
| normalize, downsample | `samtools` |
| bigwig_rep, bigwig_merged | `deeptools` (also `samtools` for merged) |
| featurecounts | `subread` |
| call_peaks | `MACS2/2.2.9.1` |
| multiqc | `multiqc` |

---

## Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| Exit code 127 on all jobs | `sbatch` not found — Quest's `module load snakemake` runs inside Singularity without SLURM access | Install Snakemake via conda (see Setup) |
| `Cannot parse runtime value into minutes` | Snakemake 7 requires integer minutes, not `HH:MM:SS` | Change `runtime = "03:00:00"` to `runtime = 180` in all rule files and profile defaults |
| `--output` argparse collision | Snakemake interprets `--output=` as `--output-wait` | Use `-o` / `-e` short flags for sbatch |
| `cluster-status returned RUNNING` | Snakemake 7 expects lowercase status tokens | Ensure `status.sh` maps SLURM states to `running` / `success` / `failed` |
| Lock error | Previous run crashed without cleanup | Run `snakemake --unlock` |

---


