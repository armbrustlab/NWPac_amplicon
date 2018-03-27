#!/bin/bash

# 16S_process.sh

# a shell script for processing the NWPac 16S amplicon data
# Jamie Collins, Armbrust Lab, University of Washington; james.r.collins@aya.yale.edu
# some of this is based on the script "16Smothurpipeline_v2.sh" by Rachelle Lim (formerly in Armbrust Lab)

# inputs to this script: raw amplicon sequence files; some file paths in the variables section below
# outputs: OTU abundance information for input into phyloseq R analyses

# assumes:
# 1. we've already run scripts to provision a machine (if necessary) and install necessary dependencies, including mothur, 
# boost, boost-python, and rclone (perhaps with the scripts "01_vagrant_provision_ubuntu.sh" and "02_metagenomics_amplicon_provision.sh")
# 2. mothur is already be added to the path
# 3. scripts is also be added to the path

# some basic formatting directions, so that this all works correctly:
# 1. filename format (from sequencer) should be:
# PRIMER-SAMPLENAME_BARCODE_R1.fastq (e.g., V4_515F_New_V4_806R_New-64039_ATTAGCGAGT_R2.fastq)
# 2. all 16S files should begin with "V4_515F_New_V4," but can be stored in any directories or subdirectories so long as complementary 
# forward and reverse reads are stored together
# 3. the file paths between the primary fastq data directory (whatever you specify for "file_dir", below) and the locations of your
# fastq files should contain no spaces or special characters other than underscores

# ----------------------------------------------------
# specify some file locations and other variables
# ----------------------------------------------------

file_dir="/Users/jamesrco/Dropbox/Archived science projects & data/Projects & science data/2018/NWPac 16S & 18S/fastq/"
prefix="16S"
numproc=4 # number of cores/processors for tasks that can be parallelized
oligos_16S="/Users/jamesrco/Code/NWPac_amplicon/primers/16S_oligos.fa" # file containing primer sequences
# V4REF="/mnt/nfs/home/rlalim/gradientscruise/db/silva.v4.fasta"
# DB_REF="/mnt/nfs/home/rlalim/gradientscruise/db/silvaNRv128PR2plusMMETSP.fna"
# DB_TAX="/mnt/nfs/home/rlalim/gradientscruise/db/silvaNRv128PR2plusMMETSP.taxonomy"
# TAXNAME="silvaNRv128PR2plusMMETSP"
# CLASS_CUTOFF=60 #bootstrap value for classification against the reference db at which the taxonomy is deemed valid
# OTU_CUTOFF=0.03 #percent similarity at which we want to cluster OTUs
# MAXLENGTH=275 #max sequence length when merged
# BAD_TAXA="Mitochondria-unknown-Archaea-Eukaryota-Chloroplast"

# ----------------------------------------------------
# pre-processing/"cleanup" steps
# ----------------------------------------------------

# get rid of any hyphens in fastq filenames
echo "Now working on files in or in suboordinate directories to:"
echo $file_dir

echo "Converting any hyphens in filenames to underscores..."
cd ''"$file_dir"''
find . -name "*.fastq" -exec bash -c 'mv "$1" "${1//-/_}"' - '{}' \;

# count the number of sequence-containing .fastq files in the directory structure (for comparison to e.g., a sample list)
# we want to exclude from this count .fastq files such as the "unmatchedIndex.fastq" files (hence the use of the regex)
echo "Total number of .fastq files in the current directory or in suboordinate directories:"
find . -name "*[1|2].fastq" | wc -l

echo "Total number of 16S-containing .fastq files in the current directory or in suboordinate directories:"
find . -name "V4_515F_New_V4*[1|2].fastq" | wc -l

# # make a list of the fastq filenames
# echo "Saving a list of 16S .fastq filenames..."
# find . -name "V4_515F_New_V4*[1|2].fastq" > 16S_fastq_filenames.txt

# ----------------------------------------------------
# processing steps
# ----------------------------------------------------

# merge paired-end reads
# we will use mothur, but you could in theory use pear or some other software for this as well
echo "Now merging paired-end 16S reads using mothur. Check mothur logfiles for results..."

# get relative paths of all the subdirectories which contain 16S .fastq files
subdirs_16S=$(find . -type f -name 'V4_515F_New_V4_806R_New*.fastq' | grep -o "\(.*\)/" | sort -u | cut -c 3-)

# now, iterate through the list of subdirectories and generate stability files
for subdir in $subdirs_16S
do
	# sending to /dev/null to suppress output
	mothur "#make.file(inputdir='$subdir', type=fastq, prefix=${prefix}.stability)" > /dev/null
	echo "Now making mothur stability file for 16S files in directory:"
	echo $subdir
done

# report back if any unpaired files were found in directories with 16S data
echo "The following unpaired .fastq files were found in directories with 16S data:"
find . -name "${prefix}.stability.single.files" | xargs cat 

# at this point, easiest to merge the stability files into a single file
echo "Merging individual stability files; processing will proceed from here on a single pooled dataset..."
stabilityfiles_16S=$(find . -type f -name "${prefix}.stability.paired.files" -o -name "${prefix}.stability.files")
cat $stabilityfiles_16S > ${prefix}.pooled.stability.files

# merge forward and reverse reads
echo "Merging forward and reverse reads using mothur..."
mothur "#make.contigs(file='${prefix}.pooled.stability.files', processors=${numproc})"

# generate sequence quality reports
echo "Generating sequence quality reports..."
mothur "#summary.seqs(fasta='${prefix}*.trim.contigs.fasta', processors=${numproc})"

# remove primers; reads with at least one mismatch to either of the primers are discarded as *.scrap.fasta
echo "Removing primers..."
mothur "#trim.seqs(fasta='${prefix}*.trim.contigs.fasta', oligos = $oligos_16S, checkorient = T)"

# perform quality filtering; reads with any ambiguous bases or that are too long (i.e., not merged properly) are discarded
echo "Performing quality filtering..."
mothur "#screen.seqs(fasta='$(ls -t ${prefix}*.trim.fasta | head -n1), group=$(ls -t ${prefix}*.groups | head -n1), maxambig=0, maxlength=$MAXLENGTH, processors=${numproc})"
#mothur "#summary.seqs(fasta=$(ls -t ${prefix}*.fasta | head -n1), processors=${numproc})"
