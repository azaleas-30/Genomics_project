# End-to-End Short-Read Genome Assembly Pipeline

##  Overview

This repository contains an end-to-end genome assembly workflow starting from raw sequencing data retrieved from the NCBI Sequence Read Archive (SRA).

The pipeline performs:

- Raw data retrieval
- Quality control assessment
- Read trimming and adapter removal
- De novo genome assembly
- Post-assembly contig filtering

This project demonstrates reproducible bioinformatics workflow development using Conda environments, structured directories, and logging practices.

---

##  Objectives

- Retrieve public sequencing data
- Perform read-level quality assessment
- Clean reads using quality-based trimming
- Assemble genome using SPAdes
- Filter contigs based on length and coverage
- Maintain reproducible, organized project structure

---

##  Tools Used

| Tool | Purpose |
|------|----------|
| SRA Toolkit | Download sequencing data |
| FastQC | Raw read quality assessment |
| fastp | Adapter removal and trimming |
| SPAdes | De novo genome assembly |
| Biopython | Contig filtering |
| pigz | Parallel compression |
| Conda | Environment management |

---

##  Project Structure

```
project/
│
├── raw_data/        # Downloaded FASTQ files
├── raw_qa/          # FastQC reports
├── trim/            # Trimmed reads
├── asm/             # SPAdes assembly output
├── filter/          # Filtered contigs
├── logs/            # Assembly logs
```

---

##  Dataset

- **SRA Accession:** SRR34079400  
- **Source:** NCBI SRA  
- **Data Type:** Paired-end Illumina reads  

---

##  Installation

###  Create Conda Environment

```bash
conda create -n assembly -y
conda activate assembly
```

###  Install Required Tools

```bash
conda install -c bioconda -c conda-forge \
  sra-tools fastqc fastp spades pigz tree -y
```

---

##  Pipeline Workflow

---

### Step 1 — Create Directory Structure

```bash
mkdir -pv ~/project/{raw_data,raw_qa,trim,asm,filter,logs}
```

---

### Step 2 — Fetch Raw Sequencing Data

```bash
cd ~/project/raw_data
prefetch SRR34079400
fasterq-dump SRR34079400 --split-files --outdir .
pigz -fv *.fastq
```

---

### Step 3 — Quality Assessment (FastQC)

```bash
fastqc --threads 2 --outdir ~/project/raw_qa \
  ~/project/raw_data/SRR34079400_1.fastq.gz \
  ~/project/raw_data/SRR34079400_2.fastq.gz
```

FastQC evaluates:

- Per-base quality scores
- Adapter contamination
- GC content distribution
- Sequence duplication levels

---

### Step 4 — Read Trimming (fastp)

```bash
cd ~/project/trim

fastp \
  -i ~/project/raw_data/SRR34079400_1.fastq.gz \
  -I ~/project/raw_data/SRR34079400_2.fastq.gz \
  -o r1.paired.fq.gz \
  -O r2.paired.fq.gz \
  --detect_adapter_for_pe \
  --trim_poly_g \
  --cut_front \
  --cut_tail \
  --cut_window_size 4 \
  --cut_mean_quality 20 \
  --length_required 50
```

Trimming strategy:

- Automatic adapter detection
- Poly-G trimming (important for NovaSeq data)
- Sliding window quality filtering
- Minimum read length of 50 bp

---

### Step 5 — Genome Assembly (SPAdes)

```bash
spades.py \
  -1 ~/project/trim/r1.paired.fq.gz \
  -2 ~/project/trim/r2.paired.fq.gz \
  --isolate \
  -o ~/project/asm/spades \
  1> ~/project/logs/spades.stdout.log \
  2> ~/project/logs/spades.log
```

- `--isolate` mode optimized for bacterial isolates
- Standard output and error logs captured separately

---

### Step 6 — Contig Filtering

Create separate environment for compatibility:

```bash
conda create -n bpy2 python=2.7 biopython -y
conda activate bpy2
```

Filter contigs based on:

- Minimum length: 500 bp
- Minimum coverage: 10×

```bash
cd ~/project/filter

./filter.contigs.py \
  -i ../asm/spades/contigs.fasta \
  -o filtered_assembly.fna \
  -d removed-contigs.fa \
  -l 500 \
  -c 10
```

---

##  Output Files

| File | Description |
|------|------------|
| contigs.fasta | Raw assembled contigs |
| filtered_assembly.fna | High-confidence contigs |
| removed-contigs.fa | Filtered-out contigs |
| FastQC reports | Quality summaries |
| SPAdes logs | Execution logs |

---

##  Design Principles

- Modular directory structure
- Clear separation of pipeline stages
- Explicit logging
- Reproducible environment management
- Coverage and length-based post-assembly filtering

---

##  Future Improvements

- Add QUAST assembly evaluation
- Convert to Snakemake workflow
- Add Docker containerization
- Enable multi-sample batch processing
- Generate automated QC reports

---

##  Author Contribution

This project was developed as part of bioinformatics coursework.  
This repository contains my independent implementation of read preprocessing, de novo assembly, and contig filtering components.

---

##  License

Educational and research use.
