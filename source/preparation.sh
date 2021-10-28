# Identify input FBPase sequences
source/get_FBPase_sequences.sh

# Find a small number of cluster representative sequences
cd-hit -c 0.5 -n 3 -i data/kegg_uniprot_ids.FBPase.fasta \
-o intermediate/kegg_uniprot_ids.FBPase.cdhit_0.5.fasta

# Add the Synechocystis FBPase to the sequences to be searched
cat intermediate/kegg_uniprot_ids.FBPase.cdhit_0.5.fasta \
data/Syn6803_P73922_FBPase.fasta > intermediate/jackhmmer_targets.fasta

# Split the targets into eight separate files
source/split_fasta.py intermediate/jackhmmer_targets.fasta 8 \
intermediate/jackhmmer_targets

# Search UniProt for related sequences using JackHMMer
ls intermediate/jackhmmer_targets.split-* | parallel --no-notice -j 8 '
  jackhmmer --cpu 4 -N 5 --noali \
  --tblout intermediate/jackhmmer.{#}.tblout.txt {} data/uniprot/uniprot.fasta \
  > >(grep -P "^#|^@" > intermediate/jackhmmer.{#}.stdout.txt) \
  2> intermediate/jackhmmer.{#}.error.txt
' &

# Get all sequences that were identified
ls intermediate/jackhmmer.*.tblout.txt | while read Infile; do
  Outfile=`echo $Infile | sed -e 's/tblout/seqids/'`
  echo "source/filter_hmmer_output.R $Infile $Outfile"
done | parallel --no-notice --jobs 9

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

# Filter sequences to only standard amino acids
source/filter_seqids_by_aa.py \
intermediate/train.unique.fasta \
intermediate/train.standard_aa.txt

source/filter_fasta_by_id.py \
intermediate/train.unique.fasta \
intermediate/train.standard_aa.txt \
intermediate/train.standard_aa.fasta

# Calculate Levenshtein distance to target sequence
source/levenshtein_distance.py \
data/Syn6803_P73922_FBPase.fasta \
intermediate/train.standard_aa.fasta \
intermediate/train.standard_aa.LD.tab

# Calculate lengths of sequences
cat intermediate/train.standard_aa.fasta | source/lengths_of_sequences.py \
> intermediate/train.standard_aa.lengths.tab

# Filter sequences by length
source/filter_sequences_by_length.R \
intermediate/train.standard_aa.lengths.tab \
intermediate/train.length_filtered.txt

# Filter sequences by Levenshtein distance to target
source/filter_sequences_by_distance.R

source/filter_fasta_by_id.py \
intermediate/train.standard_aa.fasta \
intermediate/train.filtered.txt \
intermediate/train.filtered.fasta

# Obtain taxonomy IDs and taxonomy information
(grep ">" intermediate/train.filtered.fasta | tr " " "\n" | \
grep -P "^>|^OX=" | sed -e 's/^OX=//' | tr ">" "&" | tr "\n" "\t" | \
tr "&" "\n" | sed -e 's/\t$//' | grep -v "^$") > \
intermediate/train.taxids_from_fasta.tab

# Getting full taxonomy information for the taxonomy IDs
source/taxid-to-taxonomy.py \
-i intermediate/train.taxids_from_fasta.tab \
-n data/ncbi/taxonomy/names.dmp \
-d data/ncbi/taxonomy/nodes.dmp \
-o results/train.filtered.taxonomy.tab

# Plot taxonomic distribution and Levenshtein distances of training data
source/taxonomic_distribution_of_train.R
# Makes plot "data/taxonomic_distribution_of_train.png"

# Save sequences one per line
cat intermediate/train.filtered.fasta | sed -e '/^>/ s/^>/>\t/' | cut -f 1 \
| tr -d "\n" | tr ">" "\n" | grep -vP "^$" \
> intermediate/train.txt