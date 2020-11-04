# Identify input FBPase sequences
# source/get_FBPase_sequences.sh

# Find a small number of cluster representative sequences
cd-hit -c 0.5 -n 3 -i data/kegg_uniprot_ids.FBPase.fasta \
-o intermediate/kegg_uniprot_ids.FBPase.cdhit_0.5.fasta

# Add the Synechocystis FBPase to the sequences to be searched
cat intermediate/kegg_uniprot_ids.FBPase.cdhit_0.5.fasta \
data/Syn6803_P73922_FBPase.fasta > intermediate/jackhmmer_targets.fasta

# Split the targets into eight separate files
source/split_fasta.py intermediate/jackhmmer_targets.fasta 8 \
intermediate/jackhmmer_targets

# Search UniProt for FBPase-related sequences using JackHMMer
ls intermediate/jackhmmer_targets.split-* | parallel --no-notice -j 8 '
  jackhmmer --cpu 4 -N 200 --noali \
  --tblout intermediate/jackhmmer.{#}.tblout.txt {} data/uniprot/uniprot.fasta \
  > >(grep -P "^#|^@" > intermediate/jackhmmer.{#}.stdout.txt) \
  2> intermediate/jackhmmer.{#}.error.txt
' &

# Get all sequences that were identified
ls intermediate/jackhmmer.*.tblout.txt | while read Infile; do
  Outfile=`echo $Infile | sed -e 's/tblout/seqids/'`
  source/filter_hmmer_output.R $Infile $Outfile
done

# Combine into one file with unique hits
cat intermediate/jackhmmer.*.seqids.txt | sort | uniq \
> intermediate/train.unfiltered.txt

# Extract sequences from UniProt fasta
source/filter_fasta_by_id.py \
data/uniprot/uniprot.fasta \
intermediate/train.unfiltered.txt \
intermediate/train.unfiltered.fasta

# Make sequences unique with CD-HIT
cd-hit -c 1.0 -T 0 -i intermediate/train.unfiltered.fasta \
-o intermediate/train.unique.fasta

# Calculate Levenshtein distance to target sequence
source/levenshtein_distance.py \
data/Syn6803_P73922_FBPase.fasta \
intermediate/train.unique.fasta \
intermediate/train.unique.LD.tab

# Calculate lengths of sequences
cat intermediate/train.unique.fasta | source/lengths_of_sequences.py \
> intermediate/train.unique.lengths.tab

# Filter sequences by length and Levenshtein distance to target
