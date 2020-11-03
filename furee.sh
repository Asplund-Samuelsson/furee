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
