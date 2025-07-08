# SLAM-Seq_Analysis

![SLAM-Seq Analysis](/images/SLAM-seq.png)  
- OpenAI. (2025). Scientific data visualization: SLAM-seq pipeline schematic [AI-generated image]. DALL-E. Retrieved from ChatGPT interface.

---

# 1) Summary
This workflow processes SLAM-Seq data, performing quality control on raw and trimmed FASTQ files, extracting UMIs, trimming adapters, running SlamDunk for read counts, and analyzing the data with Alleyoop for various evaluations. The final output includes BAM files, CSVs, summary files, and MultiQC reports.

---

# 2) Detailed Steps
## Steps:
+ **1)** **FastQC / MultiQC (Raw Samples)** - Perform quality control on raw FASTQ files.
+ **2)** **Process Raw Fastq UMIs** - Process UMIs (Unique Molecular Identifiers) in the raw FASTQ files.
+ **3)** **Adapter Trim (BBDuk)** - Trim adapters from the raw FASTQ files using BBDuk.
+ **4)** **FastQC / MultiQC (Trimmed Samples)** - Perform quality control on the trimmed FASTQ files.
+ **5)** **Run Slam Dunk All** - Run SlamDunk with the trimmed FASTQ files, generating BAM and count CSV files.
+ **6)** **Run Slam Dunk Count** - Count reads with SlamDunk on the BAM files generated in the previous step.
+ **7)** **Run Alleyoop Rates** - Analyze read counts and generate rates using Alleyoop.
+ **8)** **Run Alleyoop TCContext** - Analyze context-specific read distributions using Alleyoop.
+ **9)** **Run Alleyoop UTRrates** - Analyze untranslated region read counts using Alleyoop.
+ **10)** **Run Alleyoop SNPeval** - Evaluate SNPs (Single Nucleotide Polymorphisms) using Alleyoop.
+ **11)** **Run Alleyoop Summary** - Generate summary files for read counts and evaluation data.
+ **12)** **Run Alleyoop Merge** - Merge read count files for further analysis.
+ **13)** **Run Alleyoop TCperReadPos** - Analyze read positions in the context of TCs (Transcript Coordinates).
+ **14)** **Run Alleyoop Dump** - Dump all raw data for inspection and analysis.
+ **15)** **Run MultiQC on Slam Dunk Output** - Generate a final MultiQC report on all SlamDunk and Alleyoop results.

---

# 3) Instructions to run on Slurm managed HPC
3A. Download version controlled repository
```
git clone https://github.com/RD-Cobre-Help/SLAM-Seq_Analysis.git
```
3B. Load modules
```
module purge
module load slurm python/3.10 pandas/2.2.3 numpy/1.22.3 matplotlib/3.7.1
```
3C. Modify samples and config file
```
vim samples.csv
vim config.yml
```
3D. Dry Run
```
snakemake -npr
```
3E. Run on HPC with config.yml options
```
sbatch --wrap="snakemake -j 20 --use-envmodules --rerun-incomplete --latency-wait 300 --cluster-config config/cluster_config.yml --cluster 'sbatch -A {cluster.account} -p {cluster.partition} --cpus-per-task {cluster.cpus-per-task}  -t {cluster.time} --mem {cluster.mem} --output {cluster.output} --job-name {cluster.name}'"
```
