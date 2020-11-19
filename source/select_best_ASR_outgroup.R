#!/usr/bin/env Rscript
options(width=100)
library(tidyverse)

# Load data
cluster_seqids = scan("intermediate/train.cdhit_0.85.seqids.txt", character())
ordered_taxonomy = read_tsv("results/kegg_uniprot_ids.FBPase.taxonomy.tab")

# Save highest ranking sequence ID
best_seqid = ordered_taxonomy %>%
  filter(!(identifier %in% cluster_seqids), group != "Cyanobacteria") %>%
  slice_head(n=1) %>%
  pull(identifier)

writeLines(best_seqid, "intermediate/best_outgroup_seqid.txt")
