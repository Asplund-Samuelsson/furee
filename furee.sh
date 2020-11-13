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

# Takes too long for second sequence of split 1 and 3, and first of 2
# Remove output for splits 1, 2, and 3
rm intermediate/jackhmmer.[123].*

# Let first seq of 1 and 3, and second of 2 run to convergence:
# tr|A0A1J0VRF6|A0A1J0VRF6_9NOCA
# tr|A0A1Z3HIX0|A0A1Z3HIX0_9CYAN
# tr|A0A6B8KC11|A0A6B8KC11_9RHIZ

# Select the sequences to run to convergence
source/filter_fasta_by_id.py \
intermediate/kegg_uniprot_ids.FBPase.cdhit_0.5.fasta \
<(echo -e "tr|A0A1J0VRF6|A0A1J0VRF6_9NOCA
tr|A0A1Z3HIX0|A0A1Z3HIX0_9CYAN
tr|A0A6B8KC11|A0A6B8KC11_9RHIZ") \
intermediate/jackhmmer_targets.split-X0.fasta

# Run jackhmmer to convergence for three sequences
jackhmmer --cpu 8 -N 200 --noali \
--tblout intermediate/jackhmmer.X0.tblout.txt \
intermediate/jackhmmer_targets.split-X0.fasta data/uniprot/uniprot.fasta \
> >(grep -P "^#|^@" > intermediate/jackhmmer.X0.stdout.txt) \
2> intermediate/jackhmmer.X0.error.txt &

# Let second seq of 1 and 3, and first of 2 only run for five rounds (default):
# sp|P73922|FBSB_SYNY3
# tr|A9HCQ2|A9HCQ2_GLUDA
# tr|A0A075MIP8|A0A075MIP8_9PROT

# Select sequences to run only for five rounds (default)
source/filter_fasta_by_id.py \
intermediate/kegg_uniprot_ids.FBPase.cdhit_0.5.fasta \
<(echo -e "tr|A9HCQ2|A9HCQ2_GLUDA
tr|A0A075MIP8|A0A075MIP8_9PROT") \
intermediate/jackhmmer_targets.split-X1.fasta

cat data/Syn6803_P73922_FBPase.fasta \
>> intermediate/jackhmmer_targets.split-X1.fasta

# Run jackhmmer for five rounds for three sequences
jackhmmer --cpu 8 -N 5 --noali \
--tblout intermediate/jackhmmer.X1.tblout.txt \
intermediate/jackhmmer_targets.split-X1.fasta data/uniprot/uniprot.fasta \
> >(grep -P "^#|^@" > intermediate/jackhmmer.X1.stdout.txt) \
2> intermediate/jackhmmer.X1.error.txt &

# Takes too long for split X0 to finish (even though sequences converged before)
# Make new split
source/filter_fasta_by_id.py \
intermediate/jackhmmer_targets.split-X0.fasta \
<(echo -e "tr|A0A1J0VRF6|A0A1J0VRF6_9NOCA") \
intermediate/jackhmmer_targets.split-Y0.fasta

source/filter_fasta_by_id.py \
intermediate/jackhmmer_targets.split-X0.fasta \
<(echo -e "tr|A0A1Z3HIX0|A0A1Z3HIX0_9CYAN") \
intermediate/jackhmmer_targets.split-Y1.fasta

source/filter_fasta_by_id.py \
intermediate/jackhmmer_targets.split-X0.fasta \
<(echo -e "tr|A0A6B8KC11|A0A6B8KC11_9RHIZ") \
intermediate/jackhmmer_targets.split-Y2.fasta

# Remove X0 jackhmmer results
rm intermediate/jackhmmer.X0.*

# Run jackhmmer for five rounds for two sequences
jackhmmer --cpu 12 -N 5 --noali \
--tblout intermediate/jackhmmer.Y0.tblout.txt \
intermediate/jackhmmer_targets.split-Y0.fasta data/uniprot/uniprot.fasta \
> >(grep -P "^#|^@" > intermediate/jackhmmer.Y0.stdout.txt) \
2> intermediate/jackhmmer.Y0.error.txt &

jackhmmer --cpu 12 -N 5 --noali \
--tblout intermediate/jackhmmer.Y1.tblout.txt \
intermediate/jackhmmer_targets.split-Y1.fasta data/uniprot/uniprot.fasta \
> >(grep -P "^#|^@" > intermediate/jackhmmer.Y1.stdout.txt) \
2> intermediate/jackhmmer.Y1.error.txt &

# Give one sequence a chance to run to convergence
# No, it doesn't work, limit it to 5 rounds
jackhmmer --cpu 16 -N 5 --noali \
--tblout intermediate/jackhmmer.Y2.tblout.txt \
intermediate/jackhmmer_targets.split-Y2.fasta data/uniprot/uniprot.fasta \
> >(grep -P "^#|^@" > intermediate/jackhmmer.Y2.stdout.txt) \
2> intermediate/jackhmmer.Y2.error.txt &


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
# Makes plot "results/taxonomic_distribution_of_train.pdf"

# Count the number of different unique annotations from UniProt
grep ">" intermediate/train.filtered.fasta | sed -e 's/ /\t/' -e 's/ OS=/\t/' \
| cut -f 2 | sort | uniq -c | sort -nr | sed -e 's/ \+//' -e 's/ /\t/' \
> intermediate/train.filtered.annotation_summary.tab

# Prune sequences to length 274 by cutting off end and save in separate lines
seqmagick convert --cut 1:274 --output-format fasta \
intermediate/train.filtered.fasta - | sed -e '/^>/ s/^>/>\t/' | cut -f 1 \
| tr -d "\n" | tr ">" "\n" | grep -vP "^$" \
> intermediate/train.txt
