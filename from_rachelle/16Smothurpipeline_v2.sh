# 16Smothurpipeline_v2.sh
#modified to shorten filenames

#input: raw amplicon sequence files
#output: OTU abundance information for input into phyloseq R analyses
#note: mothur must already be added to the path (true if using match server)
#scripts folder must also be added to the path
#Sample name format (from sequencer): PRIMER-SAMPLENAME_BARCODE_R1.fastq (z.B. V4_515F_New_V4_806R_New-64039_ATTAGCGAGT_R2.fastq)

#Need to:
#fix the silvaNRv128PR2plusMMETSP.taxonomy file so that it is internally consistent: see what I did in fixTaxa.r
#add phytoref to the silvaNRv128PR2plusMMETSP.taxonomy database

FILEDIR="/mnt/nfs/home/rlalim/gradientscruise/16S"
OLIGOS="/mnt/nfs/home/rlalim/gradientscruise/16S/oligos.fa"
V4REF="/mnt/nfs/home/rlalim/gradientscruise/db/silva.v4.fasta"
DB_REF="/mnt/nfs/home/rlalim/gradientscruise/db/silvaNRv128PR2plusMMETSP.fna"
DB_TAX="/mnt/nfs/home/rlalim/gradientscruise/db/silvaNRv128PR2plusMMETSP.taxonomy"
TAXNAME="silvaNRv128PR2plusMMETSP"
PREFIX="16S_stations"
CLASS_CUTOFF=60 #bootstrap value for classification against the reference db at which the taxonomy is deemed valid
OTU_CUTOFF=0.03 #percent similarity at which we want to cluster OTUs
MAXLENGTH=275 #max sequence length when merged
BAD_TAXA="Mitochondria-unknown-Archaea-Eukaryota-Chloroplast"

cd $FILEDIR

#make a list of the fastq filenames
ls *.fastq > filenames.txt

#make the stability file
mothur-1-stabilityFile.py filenames.txt ${PREFIX}.stabilityfile.txt

#merge the forward and reverse reads
echo "merging reads...."
mothur "#make.contigs(file=${PREFIX}.stabilityfile.txt, processors=8)"
mothur "#summary.seqs(fasta=$(ls -t *.fasta | head -n1), processors=8)"

#remove the primers. reads with at least one mismatch to either of the primers are discarded as *.scrap.fasta
echo "removing primers...."
mothur "#trim.seqs(fasta=$(ls -t *.fasta | head -n1), oligos = oligos.fa, checkorient = T)"

#quality filtering. reads with any ambiguous bases or that are too long (i.e. not merged properly) are discarded
echo "quality filtering...."
mothur "#screen.seqs(fasta=$(ls -t *.trim.fasta | head -n1), group=$(ls -t *.groups | head -n1), maxambig=0, maxlength=$MAXLENGTH, processors=8)"
mothur "#summary.seqs(fasta=$(ls -t *.fasta | head -n1), processors=8)"

#collapse duplicate sequences. Note: mothur still keeps track of the total counts using the counts table made below, so we're not losing rel. abundance info
echo "finding unique reads...."
mothur "#unique.seqs(fasta=$(ls -t *.good.fasta | head -n1))"

#make the counts table
echo "making counts table...."
mothur-2-changeGroupFile.py $(ls -t *.good.fasta | head -n1) $(ls -t *.good.groups | head -n1) ${PREFIX}.stabilityfile.contigs.good.short.groups
mothur "#count.seqs(name=$(ls -t *.good.names | head -n1), group=$(ls -t *.short.groups | head -n1), processors=8)"

#align to the silva database. Reads that mis-align are removed
echo "screening the sequences based on alignment to silva...."
mothur "#align.seqs(fasta=$(ls -t *.unique.fasta | head -n1), reference=$V4REF, processors=8)"
mothur "#summary.seqs(fasta=$(ls -t *.unique.align | head -n1), count=$(ls -t *.good.count_table | head -n1), processors=8)"
mothur "#screen.seqs(fasta=$(ls -t *.unique.align | head -n1), count=$(ls -t *.good.count_table | head -n1), summary=$(ls -t *.summary | head -n1), optimize=start-end, maxhomop=8, processors=8)"
mothur "#filter.seqs(fasta=$(ls -t *.good.align | head -n1), vertical=T, trump=., processors=8)"
mothur "#unique.seqs(fasta=$(ls -t *.filter.fasta | head -n1), count=$(ls -t *.good.count_table | head -n1))"
mothur "#summary.seqs(fasta=$(ls -t *.fasta | head -n1), processors=8)"

#pre-cluster: reduces the error rate by collapsing reads that are within 2nt of each other
echo "preclustering reads...."
mothur "#pre.cluster(fasta=$(ls -t *.unique.fasta | head -n1), count=$(ls -t *.filter.count_table | head -n1), diffs=2)"
mothur "#summary.seqs(fasta=$(ls -t *.fasta | head -n1), processors=8)"

#remove chimeras
echo "removing chimeras..."
mothur "#chimera.uchime(fasta=$(ls -t *.precluster.fasta | head -n1), count=$(ls -t *.precluster.count_table | head -n1), dereplicate=t, processors=8)"
mothur "#remove.seqs(fasta=$(ls -t *.precluster.fasta | head -n1), accnos=$(ls -t *.accnos | head -n1))"
mothur "#summary.seqs(fasta=$(ls -t *.fasta | head -n1), count=$(ls -t *.pick.count_table | head -n1), processors=8)"

#discard singletons to reduce error rate further
echo "discarding singletons...."
mothur "#split.abund(fasta=$(ls -t *.pick.fasta | head -n1), count=$(ls -t *.pick.count_table | head -n1), cutoff=1, accnos=true)"

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

