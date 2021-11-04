# Create output directory
mkdir -p results/Rubisco/dummy

# Cluster training sequences at high sequence identity threshold
cd-hit -T 0 -c 0.84 -d 0 -i intermediate/Rubisco_KOs.fasta \
-o results/Rubisco/dummy/train.cdhit.fasta

# Create a cluster table
cat results/Rubisco/dummy/train.cdhit.fasta.clstr | source/chipp.py \
> results/Rubisco/dummy/train.cdhit.tab

# Determine cluster of Synechocystis sequence
SYN=`grep ">" data/Syn6803_P54205_Rubisco.fasta | cut -f 1 -d \  | tr -d ">"`
CLUSTER=`grep -P "\t\Q${SYN}\E\t" results/Rubisco/dummy/train.cdhit.tab | cut -f 1`

# Get all members of the Synechocystis cluster
grep -P "^${CLUSTER}\t" results/Rubisco/dummy/train.cdhit.tab | cut -f 2 \
> results/Rubisco/dummy/train.cdhit.seqids.txt

# Extract Synechocystis cluster sequences
source/filter_fasta_by_id.py \
intermediate/Rubisco_KOs.fasta \
results/Rubisco/dummy/train.cdhit.seqids.txt \
results/Rubisco/dummy/train.cdhit.raw.fasta

# Keep only ID in FASTA header in order to not mess up trees
cat results/Rubisco/dummy/train.cdhit.raw.fasta | cut -f 1 -d \  \
> results/Rubisco/dummy/train.cdhit.fasta

# Align cluster sequences
mafft --thread 16 results/Rubisco/dummy/train.cdhit.fasta \
> results/Rubisco/dummy/train.cdhit.ali.fasta

# Make tree
fasttreeMP results/Rubisco/dummy/train.cdhit.ali.fasta \
> results/Rubisco/dummy/train.cdhit.tree

# Submit data to FireProt-ASR (http://loschmidt.chemi.muni.cz/fireprotasr/)
# Use Synechocystis sequence as the "query"
# Default settings

# Save the ancestral sequences FASTA and tree files
# results/Rubisco/dummy/FireProt_ASR.fasta
# results/Rubisco/dummy/FireProt_ASR.tree

# Extract node heights
source/ancestral_distance_from_root.R \
results/Rubisco/dummy/FireProt_ASR.tree \
results/Rubisco/dummy/ancestral_tree_heights.tab

# Format data for use with top model script
tail -n +2 results/Rubisco/dummy/ancestral_tree_heights.tab | \
while read line; do
  seqid=`echo -e "$line" | cut -f 2`
  height=`echo -e "$line" | cut -f 1`
  sequence=`
    source/filter_fasta_by_id.py results/Rubisco/dummy/FireProt_ASR.fasta \
    <(echo $seqid) /dev/stdout | grep -v ">" | tr -d "\-\n"
  `
  echo -e "${sequence}\t${height}"
done | shuf -n 24 > data/Rubisco_dummy.train.tab
