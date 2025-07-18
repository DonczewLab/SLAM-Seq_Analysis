[![DOI](https://zenodo.org/badge/991471979.svg)](https://doi.org/10.5281/zenodo.16106789)

# SLAM-Seq_Analysis

![SLAM-Seq Analysis](/images/SLAM-seq.png)  
- OpenAI. (2025). Scientific data visualization: SLAM-seq pipeline schematic [AI-generated image]. DALL-E. Retrieved from ChatGPT interface.

---

## 1) Project Description

**SLAM-Seq_Analysis** is a modular, high-throughput Snakemake pipeline designed to analyze **SLAM-Seq** data. It quantifies RNA synthesis and degradation by detecting **T>C transitions**. This pipeline processes raw **paired-end FASTQ** files through quality control, UMI extraction, adapter trimming, alignment, mutation counting, and context-specific mutation analysis using **SLAM-Dunk** and **Alleyoop**. The final output includes BAM files, CSVs, summary files, and MultiQC reports.

It supports both **default 1-TC** and **custom 2-TC** read count thresholds for downstream comparative analysis and includes fully automated **MultiQC** reports for raw, trimmed, and SLAM-Dunk outputs.

### Key Features

+ **UMI Support**  
  + Extracts UMIs using `fastp`, allowing for duplicate-aware alignment and quantification

+ **Optional Adapter Trimming Method**  
  + Choose between **Trim Galore** or **BBduk** using a config flag

+ **Comprehensive QC Reports**  
  + FastQC on raw and trimmed reads  
  + MultiQC reports summarize results in unified HTML

+ **SLAM-Dunk Integration**  
  + `slam-dunk all`: Align, filter, SNP call, and count  
  + `slam-dunk count`: Rerun mutation quantification with 2-TC threshold

+ **Alleyoop Analysis**  
  + Generates mutation rates, context, UTR rates, SNP evaluation  
  + Summarizes and merges mutation counts across samples  
  + Outputs T>C mutation information per read and UTR position

+ **Scalable and Reproducible**  
  + Parallelizable via Snakemake  
  + Designed for Slurm HPC environments

---

## 2) Intended Use Case

This pipeline is built for researchers analyzing **RNA turnover** via **SLAM-seq**, especially when interested in:

+ Mutation counts (T>C transitions) per gene or region  
+ Comparing samples using 1-TC vs. 2-TC thresholds  
+ Producing summary metrics and mutation contexts  
+ Running in a reproducible and modular HPC environment

Starting from raw paired-end FASTQs, it provides all necessary intermediate and final outputs, from filtered BAMs to mutation summaries and log diagnostics.

---

## 3) Dependencies and Configuration

All user-defined settings and tool versions are declared in `config/config.yml`.

**Key fields include**:
+ `scer_genome`: reference genome FASTA  
+ `bed_file`: annotation BED file  
+ `bbmap_ref`: adapter reference for BBduk (optional)  
+ `umi_loc`, `umi_len`: UMI extraction parameters  
+ `trim_5p`, `max_read_length`, `min_base_qual`: parameters for SLAM-Dunk  
+ `use_trim_galore`: Boolean to toggle trimming tool  
+ `stringency`, `length`: used by Trim Galore

**Tool Versions**  
+ `fastqc`, `multiqc`, `fastp`, `bbmap`, `trim_galore`, `slamdunk`, `samtools`, `varscan`, `nextgenmap`

---

## 4) Tools & Modules

This pipeline uses the following tools via HPC environment modules:

+ **FastQC** — raw and trimmed read QC  
+ **MultiQC** — unified reporting of QC metrics  
+ **Fastp** — UMI extraction  
+ **BBduk** or **Trim Galore** — adapter trimming  
+ **SLAM-Dunk** — alignment, mutation calling, filtering  
+ **Alleyoop** — contextual mutation analysis and merging  
+ **Samtools**, **VarScan**, **NextGenMap** — used internally by SLAM-Dunk  
+ **Snakemake** — workflow management

---

## 5) Example `samples.csv`

Your `config/samples.csv` file should look like this:

| sample           | fastq1                              | fastq2                              | merge_group |
|------------------|-------------------------------------|-------------------------------------|-------------|
| **RDY73_DMSO_A** | /path/RDHTS192_S63_R1_001.fastq.gz  | /path/RDHTS192_S63_R2_001.fastq.gz  | DMSO        |
| **RDY73_IAA_A**  | /path/RDHTS193_S64_R1_001.fastq.gz  | /path/RDHTS193_S64_R2_001.fastq.gz  | IAA         |
| **RDY73_DMSO_B** | /path/RDHTS195_S66_R1_001.fastq.gz  | /path/RDHTS195_S66_R2_001.fastq.gz  | DMSO        |
| **RDY73_IAA_B**  | /path/RDHTS196_S67_R1_001.fastq.gz  | /path/RDHTS196_S67_R2_001.fastq.gz  | IAA         |
| **RDY73_DMSO_C** | /path/RDHTS198_S69_R1_001.fastq.gz  | /path/RDHTS198_S69_R2_001.fastq.gz  | DMSO        |
| **RDY73_IAA_C**  | /path/RDHTS199_S70_R1_001.fastq.gz  | /path/RDHTS199_S70_R2_001.fastq.gz  | IAA         |

+ **sample**: unique ID used to label output files  
+ **fastq1/fastq2**: paired-end FASTQ paths  
+ **merge_group**: optional group for downstream averaging or plotting

---

## 6) Output Structure

The pipeline generates output across several folders:

1. **Quality Control**
   + `results/qc/raw/fastqc/` — FastQC HTML/ZIP for raw FASTQs  
   + `results/qc/raw/multiqc/` — MultiQC report for raw reads  
   + `results/qc/trimmed/fastqc/` — FastQC on trimmed FASTQs  
   + `results/qc/trimmed/multiqc/` — MultiQC report for trimmed reads

2. **Preprocessing**
   + `results/fastp/` — FASTQs with UMIs extracted  
   + `results/trimmed/` — Adapter-trimmed FASTQs  

3. **SLAM-Dunk Core Output**
   + `results/slamdunk_scer/filter/` — Filtered BAM files  
   + `results/slamdunk_scer/count/` — 1-TC tcount TSVs, logs, bedgraphs  
   + `results/slamdunk_scer/count_twotcreadcount/` — 2-TC threshold tcount files

4. **Alleyoop Output**
   + `alleyoop/rates/` — overall mutation rates  
   + `alleyoop/tccontext/` — T>C context profiles  
   + `alleyoop/utrrates/` — UTR region mutation rates  
   + `alleyoop/snpeval/` — SNP evaluation outputs  
   + `alleyoop/tcperreadpos/` — mutation per read  
   + `alleyoop/tcperutrpos/` — mutation per UTR position  
   + `alleyoop/dump/` — `.sdunk` read info dump  
   + `alleyoop/summary_*` — summary stats for 1-TC and 2-TC thresholds  
   + `alleyoop/merge_*` — merged summary tables across all samples

5. **Final QC**
   + `results/qc/slamdunk_scer/multiqc/` — Summary MultiQC report of SLAM-Dunk logs

---

## 7) Instructions to Run on HPC
7A. Download version controlled repository
```
git clone https://github.com/RD-Cobre-Help/SLAM-Seq_Analysis.git
```
7B. Load modules
```
module purge
module load slurm python/3.10 pandas/2.2.3 numpy/1.22.3 matplotlib/3.7.1
```
7C. Modify samples and config file
```
vim samples.csv
vim config.yml
```
7D. Dry Run
```
snakemake -npr
```
7E. Run on HPC with config.yml options
```
sbatch --wrap="snakemake -j 20 --use-envmodules --rerun-incomplete --latency-wait 300 --cluster-config config/cluster_config.yml --cluster 'sbatch -A {cluster.account} -p {cluster.partition} --cpus-per-task {cluster.cpus-per-task}  -t {cluster.time} --mem {cluster.mem} --output {cluster.output} --job-name {cluster.name}'"
```
