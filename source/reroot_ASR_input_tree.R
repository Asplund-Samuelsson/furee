#!/usr/bin/env Rscript
options(width=100)
library(phytools)

# Load data
outgroup_seqid = scan("intermediate/best_outgroup_seqid.txt", character())
tree = read.tree("intermediate/train.cdhit_0.85.Synechocystis.tree")

# Write rooted tree
write.tree(
  root(tree, outgroup_seqid, resolve.root=T),
  "intermediate/train.cdhit_0.85.Synechocystis.rooted.tree"
)
