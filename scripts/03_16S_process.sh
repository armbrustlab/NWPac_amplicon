#!/bin/bash

# 03_16S_process.sh

# a shell script for processing the NWPac 16S amplicon data
# Jamie Collins, Armbrust Lab, University of Washington; james.r.collins@aya.yale.edu
# some of this is based on the script "16Smothurpipeline_v2.sh" by Rachelle Lim (formerly in Armbrust Lab)
# ... and a lot of @rachellelim's pipeline was based on the directions here: https://mothur.org/wiki/MiSeq_SOP

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
# top-level directory under which all .fastq files reside; this is also where mothur output will be
# dumped
prefix="16S" # file prefix to be appended
numproc=4 # number of cores/processors for tasks that can be parallelized
oligos_16S="../primers/16S_oligos.fa" # path to file containing primer sequences
maxlength=275 # max sequence length when merged
supplied_v4ref="../databases/silva.v4.fasta" # path to mothur-compatible reference database for sequence
                                             # alignment; must be specified unless you want this script
                                             # to try and retrieve the latest one for you from
                                             # https://www.mothur.org/wiki/Silva_reference_files
# supplied_DB_ref="/mnt/nfs/home/rlalim/gradientscruise/db/silvaNRv128PR2plusMMETSP.fna"
# supplied_DB_tax="/mnt/nfs/home/rlalim/gradientscruise/db/silvaNRv128PR2plusMMETSP.taxonomy"
# TAXNAME="silvaNRv128PR2plusMMETSP"
# CLASS_CUTOFF=60 # bootstrap value for classification against the reference db at which the taxonomy 
                  # is deemed valid
# OTU_CUTOFF=0.03 #percent similarity at which we want to cluster OTUs
# MAXLENGTH=275 #max sequence length when merged
# BAD_TAXA="Mitochondria-unknown-Archaea-Eukaryota-Chloroplast"

# ----------------------------------------------------
# get, store some environment information and user preferences
# ----------------------------------------------------

script_dir=$(pwd) # assuming, of course, that user calls this script from the scripts directory

# ask user whether he/she wants to retrieve the latest database from https://www.mothur.org/wiki/Silva_reference_files or use his/her own; if the former, go and fetch the database and get it ready
while true; do
	read -p "Do you want me to try and retrieve the latest mothur-compatible Silva reference database for you? [Y/n] " yn
	case $yn in
		[Yy]* ) genNewrefDB=true; break;;
		[Nn]* ) genNewrefDB=false; break;;
		* ) echo "Please answer (Y)es or (n)o before proceeding.";;
	esac
done

if [ "${genNewrefDB}" == true ]; then
	
	# *** if this doesn't work (which is possible, since I'm quite sure there's no API for the mothur wiki page),
	# user should manually download the latest "Full length sequences and taxonomy references" file from
	# https://www.mothur.org/wiki/Silva_reference_files

	source ${script_dir}/get_mothurSilvafile.sh

	# now, get the DB set up for processing our 16S data per http://blog.mothur.org/2018/01/10/SILVA-v132-reference-files/

	cd ~/databases/
	Silva_alignFile=$(ls -t | egrep '(Silva|silva)\.nr_v.*align' | head -n1)
	echo; echo "Extracting 16S V4 subset from mothur-compatible Silva reference database '${Silva_alignFile}'..."

	mothur "#pcr.seqs(fasta=${Silva_alignFile}, start=11894, end=25319, keepdots=F, processors=${numproc});unique.seqs()"
	# should generate a file ending in something like *.pcr.align

	# ensure we set variable 'v4ref' to point to the new reference database we just generated
	v4ref=$(ls -lrt -d -1 "${PWD}"/${Silva_alignFile%.align}.pcr.align | head -n1)

	# get some info about the full (new) ref DB
	mothur "#summary.seqs(fasta='${v4ref}')"

	# get some summary info about the reference file containing unique seqs
	mothur "#summary.seqs(fasta='$(ls -lrt -d -1 "${PWD}"/${Silva_alignFile%.align}.pcr.unique.align | head -n1)')"

	echo "Reference database ready for use. Proceeding with processing of .fastq files."; echo

elif [ "${genNewrefDB}" == false ]; then

	# user wants to use a supplied database
	v4ref="${supplied_v4ref}"

fi

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
mothur "#summary.seqs(fasta=$(ls -t ${prefix}*.trim.contigs.fasta | head -n1), processors=${numproc})"

# remove primers; reads with at least one mismatch to either of the primers are discarded as *.scrap.fasta
echo "Removing primers..."
mothur "#trim.seqs(fasta=$(ls -t ${prefix}*.trim.contigs.fasta | head -n1), oligos = $oligos_16S, checkorient = T,\
 processors=${numproc})"

# perform quality filtering; reads with any ambiguous bases or that are too long (i.e., not merged properly) are discarded
echo "Performing quality filtering..."
mothur "#screen.seqs(fasta=$(ls -t ${prefix}*.trim.fasta | head -n1), group=$(ls -t ${prefix}*.groups | head -n1),\
 maxambig=0, maxlength=${maxlength}, processors=${numproc})"
mothur "#summary.seqs(fasta=$(ls -t ${prefix}*.trim.good.fasta | head -n1), processors=${numproc})"

# collapse duplicate sequences; note that we'll still get a list of the total no. of counts 
# per sequence when we run the count.seqs() command below (results will be in the .count_table)
# so, we're not losing rel. abundance info
echo "Finding unique reads..."
mothur "#unique.seqs(fasta=$(ls -t ${prefix}*.trim.good.fasta | head -n1))"

# make counts table
# *** note that we can't make counts table directly due to mismatches between our groups file and
# our contigs file; we can use a short python script mothur-2-changeGroupFile.py
# written by @rachellelim to perform the necessary matching

echo "Making counts table..."
echo "First, calling Python script to fix mismatches between groups file and contigs file. You must have Python 2.7 installed, with the package Biopython and its dependencies..."
# ${code_dir}/mothur-2-changeGroupFile.py $(ls -t ${prefix}*.good.fasta | head -n1) $(ls -t ${prefix}*.good.groups | head -n1) ${prefix}.stabilityfile.contigs.good.short.groups # only works if mothur-2-changeGroupFile.py is executable
python2 ${script_dir}/mothur-2-changeGroupFile.py $(ls -t ${prefix}*.good.fasta | head -n1) $(ls -t ${prefix}*.good.groups | head -n1) ${prefix}.stabilityfile.contigs.good.short.groups
mothur "#count.seqs(name=$(ls -t ${prefix}*.good.names | head -n1), group=$(ls -t ${prefix}*.short.groups | head -n1), processors=${numproc})"
mothur "#summary.seqs(fasta=$(ls -t ${prefix}*.trim.good.count_table | head -n1), processors=${numproc})" # get some updated information

# ----------------------------------------------------
# sequence alignment to reference database
# ----------------------------------------------------

# align our sequences to a 16S V4 region reference database; reads that mis-align will be removed
# we'll use a version of the Silva database for this task

# assumes user has supplied a reference database (variable "supplied_v4ref") or one has been downloaded
# above from the mothur wiki site

echo "Screening sequences based on alignment to Silva. Using reference database ${v4ref} ..."
mothur "#align.seqs(fasta=$(ls -t ${prefix}*.good.unique.fasta | head -n1), reference='${v4ref}', processors=${numproc})"
mothur "#summary.seqs(fasta=$(ls -t ${prefix}*.good.unique.align | head -n1), count=$(ls -t ${prefix}*.trim.good.count_table | head -n1), processors=${numproc})"
mothur "#screen.seqs(fasta=$(ls -t ${prefix}*.good.unique.align | head -n1), count=$(ls -t ${prefix}*.trim.good.count_table | head -n1), summary=$(ls -t ${prefix}*.good.unique.summary | head s-n1), optimize=start-end, maxhomop=8, processors=${numproc})"
mothur "#filter.seqs(fasta=$(ls -t ${prefix}*.good.unique.good.align | head -n1), vertical=T, trump=., processors=${numproc})"
mothur "#unique.seqs(fasta=$(ls -t ${prefix}*.good.unique.good.filter.fasta | head -n1), count=$(ls -t ${prefix}*.trim.good.count_table | head -n1))"
mothur "#summary.seqs(fasta=$(ls -t ${prefix}*.good.unique.good.filter.unique.fasta | head -n1), processors=${numproc})"

# ----------------------------------------------------
# clustering and classifying
# ----------------------------------------------------

# pre-cluster: reduces the error rate by collapsing reads that are within 2nt of each other (may take a long time)
echo "Preclustering reads..."
mothur "#pre.cluster(fasta=$(ls -t ${prefix}*.good.unique.good.filter.unique.fasta | head -n1), count=$(ls -t ${prefix}*.good.unique.good.filter.count_table | head -n1), diffs=2, processors=${numproc})"
mothur "#summary.seqs(fasta=$(ls -t ${prefix}*.good.unique.good.filter.unique.precluster.fasta | head -n1), processors=${numproc})"

# remove chimeras
echo "Removing chimeras..."
mothur "#chimera.uchime(fasta=$(ls -t ${prefix}*.good.unique.good.filter.unique.precluster.fasta | head -n1), count=$(ls -t ${prefix}*.good.unique.good.filter.unique.precluster.count_table | head -n1), dereplicate=t, processors=${numproc})"
mothur "#remove.seqs(fasta=$(ls -t ${prefix}*.precluster.fasta | head -n1), accnos=$(ls -t *.accnos | head -n1))"
mothur "#summary.seqs(fasta=$(ls -t ${prefix}*.fasta | head -n1), count=$(ls -t ${prefix}*.pick.count_table | head -n1), processors=${numproc})"

# discard singletons to reduce error rate further
echo "Discarding singletons..."
mothur "#split.abund(fasta=$(ls -t ${prefix}*.pick.fasta | head -n1), count=$(ls -t ${prefix}*.pick.count_table | head -n1), cutoff=1, accnos=true)"
#where Jamie got to,  need to find correct reference database to go any further.

#classify sequences against reference database
echo "classifying sequences against reference database...."
mothur "#classify.seqs(fasta=$(ls -t *.abund.fasta | head -n1), count=$(ls -t *.abund.count_table | head -n1), reference=$DB_REF, taxonomy=$DB_TAX, cutoff=$CLASS_CUTOFF, processors = 8)"

#removing taxa that we're not interested in! 
echo "removing reads from" $BAD_TAXA
mothur "#remove.lineage(fasta=$(ls -t *.abund.fasta | head -n1), count=$(ls -t *.abund.count_table | head -n1), taxonomy=$(ls -t *.wang.taxonomy | head -n1), taxon=$BAD_TAXA)"

#renaming sequences to add the group (ie the sample name)
echo "renaming sequences......"
mothur "#rename.seqs(fasta=$(ls -t *.pick.fasta | head -n1))"
mothur-3-renameFiles.py $(ls -t *.renamed_map | head -n1) $(ls -t *.pick.count_table | head -n1) ${PREFIX}.renamed.count_table $(ls -t *.${TAXNAME}.wang.pick.taxonomy | head -n1) ${PREFIX}.renamed.taxonomy
mothur "#summary.seqs(fasta=$(ls -t *.fasta | head -n1), count=$(ls -t *.count_table | head -n1), processors=8)"

#cluster into OTUs
echo "clustering into OTUs......"
echo "note: this step can take a VERY!!! long time"
mothur "#cluster.split(fasta=$(ls -t *.renamed.fasta | head -n1), count=${PREFIX}.renamed.count_table, taxonomy=${PREFIX}.renamed.taxonomy, splitmethod=classify, taxlevel=4, cutoff=0.03, cluster=f, processors=8)"
mothur "#cluster.split(file=$(ls -t *.renamed.file | head -n1), processors=7)"

#synthesize into shared file
echo "make summary file......"
mothur "#make.shared(list=$(ls -t *.list | head -n1), count=${PREFIX}.renamed.count_table, label=$OTU_CUTOFF)"

#classify OTUs using the consensus taxonomy from the sequence classification
echo "classifying OTUs based on sequence consensus taxonomy...."
mothur "#classify.otu(list=$(ls -t *.list | head -n1), count=${PREFIX}.renamed.count_table, taxonomy=${PREFIX}.renamed.taxonomy, label=$OTU_CUTOFF)"
mv $(ls -t *.shared | head -n1) ${PREFIX}.stability.an.shared
mv $(ls -t *.cons.taxonomy | head -n1) ${PREFIX}.stability.an.cons.taxonomy
echo "pipeline completed!"
echo "use" ${PREFIX}.stability.an.shared "for your downstream analyses!"

