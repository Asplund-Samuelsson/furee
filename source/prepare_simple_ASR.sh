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

# Find closely related reference sequences
phmmer --noali \
--tblout intermediate/Syn6803_P73922_FBPase.reference_hits.tblout.txt \
data/Syn6803_P73922_FBPase.fasta data/kegg_uniprot_ids.FBPase.fasta

# Extract hit IDs in order of best to worst hit
grep -v "^#" intermediate/Syn6803_P73922_FBPase.reference_hits.tblout.txt \
| cut -f 1 -d \  > intermediate/Syn6803_P73922_FBPase.reference_hits.txt

# Get taxonomic information for reference hits
(grep ">" data/kegg_uniprot_ids.FBPase.fasta | tr " " "\n" | \
grep -P "^>|^OX=" | sed -e 's/^OX=//' | tr ">" "&" | tr "\n" "\t" | \
tr "&" "\n" | sed -e 's/\t$//' | grep -v "^$") > \
intermediate/kegg_uniprot_ids.FBPase.taxids_from_fasta.tab

source/taxid-to-taxonomy.py \
-i intermediate/kegg_uniprot_ids.FBPase.taxids_from_fasta.tab \
-n data/ncbi/taxonomy/names.dmp \
-d data/ncbi/taxonomy/nodes.dmp \
-o results/kegg_uniprot_ids.FBPase.taxonomy.tab

# Check that order is retained
diff <(tail -n +2 results/kegg_uniprot_ids.FBPase.taxonomy.tab | cut -f 1,2) \
<(cat intermediate/kegg_uniprot_ids.FBPase.taxids_from_fasta.tab)

# Select the best non-Cyano hit that is not in the cluster
source/select_best_ASR_outgroup.R
# Generates "intermediate/best_outgroup_seqid.txt"

# Extract outgroup sequence
source/filter_fasta_by_id.py \
data/kegg_uniprot_ids.FBPase.fasta \
intermediate/best_outgroup_seqid.txt \
intermediate/ASR_outgroup.fasta

# Add outgroup and keep only ID in FASTA header in order to not mess up trees
cat intermediate/train.cdhit_0.85.Synechocystis.raw.fasta \
intermediate/ASR_outgroup.fasta | cut -f 1 -d \  \
> intermediate/train.cdhit_0.85.Synechocystis.fasta

# Align cluster sequences
mafft --thread 16 intermediate/train.cdhit_0.85.Synechocystis.fasta \
> intermediate/train.cdhit_0.85.Synechocystis.ali.fasta

# Make tree
fasttreeMP intermediate/train.cdhit_0.85.Synechocystis.ali.fasta \
> intermediate/train.cdhit_0.85.Synechocystis.tree

# Re-root tree at outgroup
source/reroot_ASR_input_tree.R
# Generates "intermediate/train.cdhit_0.85.Synechocystis.rooted.tree"

# Submit data to FireProt-ASR (http://loschmidt.chemi.muni.cz/fireprotasr/)
# Use Synechocystis sequence as the "query"
# Default settings

# Save the ancestral sequences FASTA and tree files
# data/FireProt_Syn6803_ASR.fasta
# data/FireProt_Syn6803_ASR.tree
