#!/usr/bin/env bash

# Read infile, target sequence, and output directory from command line
INFILE=$1 # FASTA file with JackHMMer targets
TARGET=$2 # FASTA file with single in silico evolution target sequence
IDNTTY=$3 # Identity cutoff for CD-HIT clustering
LENMAD=$4 # Number of MADs to define allowed length range
LEVCUT=$5 # Levenshtein distance to target cutoff
OUTDIR=$6 # Output directory

# Set up preparation log file with time and date
mkdir -p ${OUTDIR}

################################################################################

# STEP 1: jackhmmer
mkdir -p ${OUTDIR}/jackhmmer # Output directory
LOGFILE="${OUTDIR}/jackhmmer/jackhmmer.log" # Logfile
date > $LOGFILE 2>&1 # Log start time

# Determine number of files to split targets into
N=`(echo 8; grep -c ">" $INFILE) | sort -n | head -1` >> $LOGFILE 2>&1

# Split the targets into separate files
source/split_fasta.py $INFILE $N ${OUTDIR}/jackhmmer/targets >> $LOGFILE 2>&1

# Search UniProt for related sequences using JackHMMer
for i in $( eval echo {0..$(($N-1))} ); do
  echo "jackhmmer --cpu 4 -N 5 --noali \
  --tblout ${OUTDIR}/jackhmmer/jackhmmer.${i}.tblout.txt \
  ${OUTDIR}/jackhmmer/targets.split-${i}.fasta \
  data/uniprot/uniprot.fasta \
  > >(grep -P '^#|^@' > ${OUTDIR}/jackhmmer/jackhmmer.${i}.stdout.txt) \
  2> ${OUTDIR}/jackhmmer/jackhmmer.${i}.error.txt
  "
done | parallel --no-notice -j $N >> $LOGFILE 2>&1

# Get all sequences that were identified
source/filter_hmmer_output.R \
${OUTDIR}/jackhmmer \
${OUTDIR}/jackhmmer/train.unfiltered.txt >> $LOGFILE 2>&1

# Extract sequences from UniProt fasta
source/filter_fasta_by_id.py \
data/uniprot/uniprot.fasta \
${OUTDIR}/jackhmmer/train.unfiltered.txt \
${OUTDIR}/jackhmmer/train.unfiltered.fasta >> $LOGFILE 2>&1

################################################################################

# STEP 2: cdhit
mkdir -p ${OUTDIR}/cdhit # Output directory
LOGFILE="${OUTDIR}/cdhit/cdhit.log" # Logfile
date > $LOGFILE 2>&1 # Log start time

# Make sequences unique with CD-HIT
cd-hit -c $IDNTTY -T 0 -M 28000 -i ${OUTDIR}/jackhmmer/train.unfiltered.fasta \
-o ${OUTDIR}/cdhit/train.unique.fasta >> $LOGFILE 2>&1

################################################################################

# STEP 3: aa
mkdir -p ${OUTDIR}/aa # Output directory
LOGFILE="${OUTDIR}/aa/aa.log" # Logfile
date > $LOGFILE 2>&1 # Log start time

# Filter sequences to only standard amino acids
source/filter_seqids_by_aa.py \
${OUTDIR}/cdhit/train.unique.fasta \
${OUTDIR}/aa/train.standard_aa.txt >> $LOGFILE 2>&1

source/filter_fasta_by_id.py \
${OUTDIR}/cdhit/train.unique.fasta \
${OUTDIR}/aa/train.standard_aa.txt \
${OUTDIR}/aa/train.standard_aa.fasta >> $LOGFILE 2>&1

################################################################################

# STEP 4: distance
mkdir -p ${OUTDIR}/distance # Output directory
LOGFILE="${OUTDIR}/distance/distance.log" # Logfile
date > $LOGFILE 2>&1 # Log start time

# Calculate Levenshtein distance to target sequence
source/levenshtein_distance.py \
$TARGET \
${OUTDIR}/aa/train.standard_aa.fasta \
${OUTDIR}/distance/train.standard_aa.LD.tab >> $LOGFILE 2>&1

# Calculate lengths of sequences
cat ${OUTDIR}/aa/train.standard_aa.fasta | \
source/lengths_of_sequences.py \
> ${OUTDIR}/distance/train.standard_aa.lengths.tab 2>> $LOGFILE

# Filter sequences by length
source/filter_sequences_by_length.R \
${OUTDIR}/distance/train.standard_aa.lengths.tab \
$LENMAD \
${OUTDIR}/distance/train.length_filtered.txt >> $LOGFILE 2>&1

# Filter sequences by Levenshtein distance to target
source/filter_sequences_by_distance.R \
${OUTDIR}/distance/train.standard_aa.LD.tab \
${OUTDIR}/distance/train.length_filtered.txt \
$LEVCUT \
${OUTDIR}/distance/train.filtered.txt >> $LOGFILE 2>&1

# Extract filtered sequences from FASTA
source/filter_fasta_by_id.py \
${OUTDIR}/aa/train.standard_aa.fasta \
${OUTDIR}/distance/train.filtered.txt \
${OUTDIR}/distance/train.filtered.fasta >> $LOGFILE 2>&1

# Summarise hit annotations
grep ">" ${OUTDIR}/distance/train.filtered.fasta | \
sed -e 's/ /\t/' -e 's/ OS=/\t/' | cut -f 2 | sort | uniq -c | sort -rn \
> ${OUTDIR}/hits.txt 2>> $LOGFILE

# Save sequences one per line
cat ${OUTDIR}/distance/train.filtered.fasta | sed -e '/^>/ s/^>/>\t/' | \
cut -f 1 | tr -d "\n" | tr ">" "\n" | grep -vP "^$" \
> ${OUTDIR}/train.txt 2>> $LOGFILE

################################################################################

# STEP 5: taxonomy
mkdir -p ${OUTDIR}/taxonomy # Output directory
LOGFILE="${OUTDIR}/taxonomy/taxonomy.log" # Logfile
date > $LOGFILE 2>&1 # Log start time

# Obtain taxonomy IDs and taxonomy information
(grep ">" ${OUTDIR}/distance/train.filtered.fasta | tr -d "&" | \
sed -e 's/^>/\&/' | tr " " "\n" | grep -P "^&|^OX=" | sed -e 's/^OX=//' | \
tr "\n" "\t" | tr "&" "\n" | sed -e 's/\t$//' | grep -v "^$") > \
${OUTDIR}/taxonomy/train.taxids_from_fasta.tab 2>> $LOGFILE

# Get full taxonomy information for the taxonomy IDs
source/taxid-to-taxonomy.py \
-i ${OUTDIR}/taxonomy/train.taxids_from_fasta.tab \
-n data/ncbi/taxonomy/names.dmp \
-d data/ncbi/taxonomy/nodes.dmp \
-o ${OUTDIR}/taxonomy/train.filtered.taxonomy.tab >> $LOGFILE 2>&1

# Identify ID of target sequence
TARGET_ID=`grep ">" $TARGET | cut -f 1 -d \  | tr -d ">"` >> $LOGFILE 2>&1

# Plot taxonomic distribution and Levenshtein distances of training data
source/taxonomic_distribution_of_train.R \
${OUTDIR}/taxonomy/train.filtered.taxonomy.tab \
${OUTDIR}/distance/train.standard_aa.LD.tab \
"$TARGET_ID" \
"Levenshtein distance to $TARGET_ID" \
${OUTDIR}/taxonomy/taxonomic_distribution_of_train.png >> $LOGFILE 2>&1
