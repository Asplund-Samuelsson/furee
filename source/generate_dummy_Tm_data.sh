# Cluster training sequences at high sequence identity threshold
cd-hit -T 0 -c 0.85 -d 0 -i intermediate/train.filtered.fasta \
-o intermediate/train.cdhit_0.85.fasta

# Create a cluster table
cat intermediate/train.cdhit_0.85.fasta.clstr | source/chipp.py \
> intermediate/train.cdhit_0.85.tab

# Determine cluster of Synechocystis sequence
SYN=`grep ">" data/Syn6803_P73922_FBPase.fasta | cut -f 1 -d \  | tr -d ">"`
CLUSTER=`grep -P "\t\Q${SYN}\E\t" intermediate/train.cdhit_0.85.tab | cut -f 1`

# Get all members of the Synechocystis cluster
grep -P "^${CLUSTER}\t" intermediate/train.cdhit_0.85.tab | cut -f 2 \
> intermediate/train.cdhit_0.85.seqids.txt

# Extract Synechocystis cluster sequences
source/filter_fasta_by_id.py \
intermediate/train.filtered.fasta \
intermediate/train.cdhit_0.85.seqids.txt \
intermediate/train.cdhit_0.85.Synechocystis.raw.fasta

# Keep only ID in FASTA header in order to not mess up trees
cat intermediate/train.cdhit_0.85.Synechocystis.raw.fasta | cut -f 1 -d \  \
> intermediate/train.cdhit_0.85.Synechocystis.fasta

# Align cluster sequences
mafft --thread 16 intermediate/train.cdhit_0.85.Synechocystis.fasta \
> intermediate/train.cdhit_0.85.Synechocystis.ali.fasta

# Make tree
fasttreeMP intermediate/train.cdhit_0.85.Synechocystis.ali.fasta \
> intermediate/train.cdhit_0.85.Synechocystis.tree

# Submit data to FireProt-ASR (http://loschmidt.chemi.muni.cz/fireprotasr/)
# Use Synechocystis sequence as the "query"
# Default settings

# Save the ancestral sequences FASTA and tree files
# data/FireProt_Syn6803_ASR.fasta
# data/FireProt_Syn6803_ASR.tree

# Generate dummy Tm data
source/generate_dummy_ancestral_Tm.R
# Produces:
# data/dummy_ancestral_Tm_on_tree.pdf
# data/dummy_ancestral_Tm.tab

# Extract node heights
source/ancestral_distance_from_root.R \
data/FireProt_Syn6803_ASR.tree \
data/FBPase_ancestral_tree_heights.tab

# Format data for used with top model script
tail -n +2 data/dummy_ancestral_Tm.tab | while read line; do
  seqid=`echo -e "$line" | cut -f 2`
  Tm=`echo -e "$line" | cut -f 1`
  sequence=`
    source/filter_fasta_by_id.py data/FireProt_Syn6803_ASR.fasta \
    <(echo $seqid) /dev/stdout | grep -v ">" | tr -d "\-\n"
  `
  echo -e "${sequence}\t${Tm}"
done > data/dummy.sequence_Tm.tab

tail -n +2 data/FBPase_ancestral_tree_heights.tab | while read line; do
  seqid=`echo -e "$line" | cut -f 2`
  height=`echo -e "$line" | cut -f 1`
  sequence=`
    source/filter_fasta_by_id.py data/FireProt_Syn6803_ASR.fasta \
    <(echo $seqid) /dev/stdout | grep -v ">" | tr -d "\-\n"
  `
  echo -e "${sequence}\t${height}"
done > data/FBPase_dummy.sequence_height.tab
