#!/usr/bin/env Rscript

options(width=100)
library(tidyverse)
library(phytools)

# Define infiles
asr_tree_file = "data/FireProt_Syn6803_ASR.tree"

# Load data
asr_tree = read.tree(asr_tree_file)

# Edges are parent-child relations
relations = bind_cols(
  # Extract node pairs of edges
  asr_tree$edge %>% as_tibble() %>% rename(Parent = V1, Child = V2),
  # Extract node heights
  nodeHeights(asr_tree) %>% as_tibble() %>% rename(Parent_h = V1, Child_h = V2)
)

# Save height values
heights = relations %>%
  select(Child, Child_h) %>%
  rename(Height = Child_h) %>%
  bind_rows(tibble(Child = asr_tree$edge[1,1], Height=0)) %>%
  mutate(
    Sequence_ID = str_replace_all(asr_tree$tip.label, "\"", "")[Child],
    Sequence_ID = ifelse(
      is.na(Sequence_ID),
      paste("ancestral", Child, sep="_"),
      Sequence_ID
    )
  ) %>%
  select(-Child)

write_tsv(heights, "data/ancestral_tree_heights.tab")
