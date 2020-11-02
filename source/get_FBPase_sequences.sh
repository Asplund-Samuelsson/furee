# Obtain lists of UniProt IDs for bifunctional FBPase from KEGG
wget -qO - "https://www.genome.jp/dbget-bin/get_linkdb?-t+uniprot+ko:K01086" | \
grep "\[" | tr "[]" "\t" | cut -f 2 | sort | uniq > \
data/kegg_uniprot_ids.K01086_FBPase.txt

wget -qO - "https://www.genome.jp/dbget-bin/get_linkdb?-t+uniprot+ko:K11532" | \
grep "\[" | tr "[]" "\t" | cut -f 2 | sort | uniq > \
data/kegg_uniprot_ids.K11532_FBPase.txt

# Combine into one file
(
  echo "P73922";
  cat data/kegg_uniprot_ids.K01086_FBPase.txt;
  cat data/kegg_uniprot_ids.K11532_FBPase.txt
) | sort | uniq > data/kegg_uniprot_ids.FBPase.txt

# Manually download FASTA file from UniProt based on IDs obtained from KEGG
# data/kegg_uniprot.FBPase.fasta
