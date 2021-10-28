#!/usr/bin/env bash

# Read infile, target sequence, and output directory from command line
INFILE=$1 # FASTA file with JackHMMer targets
TARGET=$2 # FASTA file with single in silico evolution target sequence
OUTDIR=$3 # Output directory
LOGFILE="${OUTDIR}/preparation.log" # Logfile

# Set up preparation log file with time and date
mkdir -p ${OUTDIR}
date > $LOGFILE 2>&1

# Create intermediate and results directory
echo -en "\nLOG Creating output directories\n" >> $LOGFILE
mkdir -p ${OUTDIR}/intermediate ${OUTDIR}/results >> $LOGFILE 2>&1

# STEP 1
echo -en "\nLOG Step 1: JackHMMer\n" >> $LOGFILE

# Determine number of files to split targets into
echo -en "\nLOG 1. Determining number of splits\n" >> $LOGFILE
N=`(echo 8; grep -c ">" $INFILE) | sort -n | head -1` >> $LOGFILE 2>&1

# Split the targets into separate files
echo -en "\nLOG 1. Splitting targets\n" >> $LOGFILE
source/split_fasta.py $INFILE $N ${OUTDIR}/intermediate/targets >> $LOGFILE 2>&1

# Search UniProt for related sequences using JackHMMer
echo -en "\nLOG 1. Performing JackHMMer search\n" >> $LOGFILE
for i in $( eval echo {0..$(($N-1))} ); do
  echo "jackhmmer --cpu 4 -N 5 --noali \
  --tblout ${OUTDIR}/intermediate/jackhmmer.${i}.tblout.txt \
  ${OUTDIR}/intermediate/targets.split-${i}.fasta \
  data/uniprot/uniprot.fasta \
  > >(grep -P '^#|^@' > ${OUTDIR}/intermediate/jackhmmer.${i}.stdout.txt) \
  2> ${OUTDIR}/intermediate/jackhmmer.${i}.error.txt
  "
done | parallel --no-notice -j $N >> $LOGFILE 2>&1

# Get all sequences that were identified
echo -en "\nLOG 1. Collecting identified sequences\n" >> $LOGFILE
ls ${OUTDIR}/intermediate/jackhmmer.*.tblout.txt | while read Infile; do
  Outfile=`echo $Infile | sed -e 's/tblout/seqids/'`
  echo "source/filter_hmmer_output.R $Infile $Outfile"
done | parallel --no-notice --jobs 8 >> $LOGFILE 2>&1

# Combine into one file with unique hits
echo -en "\nLOG 1. Combining unique hits into one file\n" >> $LOGFILE
cat ${OUTDIR}/intermediate/jackhmmer.*.seqids.txt | sort | uniq \
> ${OUTDIR}/intermediate/train.unfiltered.txt 2>> $LOGFILE

# Extract sequences from UniProt fasta
echo -en "\nLOG 1. Extracting sequences from UniProt\n" >> $LOGFILE
source/filter_fasta_by_id.py \
data/uniprot/uniprot.fasta \
${OUTDIR}/intermediate/train.unfiltered.txt \
${OUTDIR}/intermediate/train.unfiltered.fasta >> $LOGFILE 2>&1

# STEP 2
echo -en "\nLOG Step 2: CD-HIT\n" >> $LOGFILE

# Make sequences unique with CD-HIT
echo -en "\nLOG 2. Making sequences unique\n" >> $LOGFILE
cd-hit -c 1.0 -T 0 -i ${OUTDIR}/intermediate/train.unfiltered.fasta \
-o ${OUTDIR}/intermediate/train.unique.fasta >> $LOGFILE 2>&1

# STEP 3
echo -en "\nLOG Step 3: Standard AAs\n" >> $LOGFILE

# Filter sequences to only standard amino acids
echo -en "\nLOG 3. Finding sequences with standard AAs\n" >> $LOGFILE
source/filter_seqids_by_aa.py \
${OUTDIR}/intermediate/train.unique.fasta \
${OUTDIR}/intermediate/train.standard_aa.txt >> $LOGFILE 2>&1

echo -en "\nLOG 3. Filtering sequences to standard AAs\n" >> $LOGFILE
source/filter_fasta_by_id.py \
${OUTDIR}/intermediate/train.unique.fasta \
${OUTDIR}/intermediate/train.standard_aa.txt \
${OUTDIR}/intermediate/train.standard_aa.fasta >> $LOGFILE 2>&1

# STEP 4
echo -en "\nLOG Step 4: Levenshtein distance (LD) and length\n" >> $LOGFILE

# Calculate Levenshtein distance to target sequence
echo -en "\nLOG 4. Calculating LD to target\n" >> $LOGFILE
source/levenshtein_distance.py $TARGET \
${OUTDIR}/intermediate/train.standard_aa.fasta \
${OUTDIR}/intermediate/train.standard_aa.LD.tab >> $LOGFILE 2>&1

# Calculate lengths of sequences
echo -en "\nLOG 4. Calculating lengths of sequences\n" >> $LOGFILE
cat ${OUTDIR}/intermediate/train.standard_aa.fasta | \
source/lengths_of_sequences.py \
> ${OUTDIR}/intermediate/train.standard_aa.lengths.tab 2>> $LOGFILE

# Filter sequences by length
echo -en "\nLOG 4. Filtering sequences by length\n" >> $LOGFILE
source/filter_sequences_by_length.R \
${OUTDIR}/intermediate/train.standard_aa.lengths.tab \
${OUTDIR}/intermediate/train.length_filtered.txt >> $LOGFILE 2>&1

# Filter sequences by Levenshtein distance to target
echo -en "\nLOG 4. Filtering sequences by LD\n" >> $LOGFILE
source/filter_sequences_by_distance.R \
${OUTDIR}/intermediate/train.standard_aa.LD.tab \
${OUTDIR}/intermediate/train.length_filtered.txt \
${OUTDIR}/intermediate/train.filtered.txt >> $LOGFILE 2>&1

echo -en "\nLOG 4. Filtering sequences by length and LD\n" >> $LOGFILE
source/filter_fasta_by_id.py \
${OUTDIR}/intermediate/train.standard_aa.fasta \
${OUTDIR}/intermediate/train.filtered.txt \
${OUTDIR}/intermediate/train.filtered.fasta >> $LOGFILE 2>&1

# STEP 5
echo -en "\nLOG Step 5: Taxonomic distribution\n" >> $LOGFILE

# Obtain taxonomy IDs and taxonomy information
echo -en "\nLOG 5. Extracting taxonomy IDs\n" >> $LOGFILE
(grep ">" ${OUTDIR}/intermediate/train.filtered.fasta | tr " " "\n" | \
grep -P "^>|^OX=" | sed -e 's/^OX=//' | tr ">" "&" | tr "\n" "\t" | \
tr "&" "\n" | sed -e 's/\t$//' | grep -v "^$") > \
${OUTDIR}/intermediate/train.taxids_from_fasta.tab 2>> $LOGFILE

# Get full taxonomy information for the taxonomy IDs
echo -en "\nLOG 5. Extracting taxonomy information\n" >> $LOGFILE
source/taxid-to-taxonomy.py \
-i ${OUTDIR}/intermediate/train.taxids_from_fasta.tab \
-n data/ncbi/taxonomy/names.dmp \
-d data/ncbi/taxonomy/nodes.dmp \
-o ${OUTDIR}/results/train.filtered.taxonomy.tab >> $LOGFILE 2>&1

# Plot taxonomic distribution and Levenshtein distances of training data
echo -en "\nLOG 5. Determining target sequence ID\n" >> $LOGFILE
TARGET_ID=`grep ">" $TARGET | cut -f 1 -d \  | tr -d ">"` >> $LOGFILE 2>&1

echo -en "\nLOG 5. Plotting taxonomic distribution of training data\n" >> $LOGFILE
source/taxonomic_distribution_of_train.R \
${OUTDIR}/results/train.filtered.taxonomy.tab \
${OUTDIR}/intermediate/train.standard_aa.LD.tab \
"$TARGET_ID" \
"Levenshtein distance to $TARGET_ID" \
${OUTDIR}/results/taxonomic_distribution_of_train.png >> $LOGFILE 2>&1

# STEP 5
echo -en "\nLOG Step 6: Create final training data file\n" >> $LOGFILE

# Save sequences one per line
echo -en "\nLOG 6. Save training sequences to file with one per line\n" >> $LOGFILE
cat ${OUTDIR}/intermediate/train.filtered.fasta | sed -e '/^>/ s/^>/>\t/' | \
cut -f 1 | tr -d "\n" | tr ">" "\n" | grep -vP "^$" \
> ${OUTDIR}/results/train.txt 2>> $LOGFILE

# Done
echo -en "\nLOG Preparation finished.\n" >> $LOGFILE
