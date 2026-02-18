#!/bin/bash

# Create conda environment
conda create -n assembly -y
conda activate assembly

# Install required tools
conda install -c bioconda -c conda-forge sra-tools fastqc fastp spades pigz tree -y

# Create project directories
mkdir -pv ~/project/{raw_data,raw_qa,trim,asm,filter,logs}

# Fetch raw sequencing data
cd ~/project/raw_data
prefetch SRR34079400
fasterq-dump SRR34079400 --split-files --outdir ~/project/raw_data
pigz -fv ~/project/raw_data/*.fastq

# Quality assessment
fastqc --threads 2 --outdir ~/project/raw_qa \
 ~/project/raw_data/SRR34079400_1.fastq.gz \
 ~/project/raw_data/SRR34079400_2.fastq.gz

# Read trimming with fastp
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

# Genome assembly with SPAdes
spades.py \
 -1 ~/project/trim/r1.paired.fq.gz \
 -2 ~/project/trim/r2.paired.fq.gz \
 --isolate \
 -o ~/project/asm/spades \
 1> ~/project/logs/spades.stdout.log \
 2> ~/project/logs/spades.log

# Create Python 2.7 environment for filtering
conda create -n bpy2 python=2.7 biopython -y
conda activate bpy2

# Filter contigs
cd ~/project/filter
./filter.contigs.py \
 -i ../asm/spades/contigs.fasta \
 -o filtered_assembly.fna \
 -d removed-contigs.fa \
 -l 500 \
 -c 10

conda deactivate
