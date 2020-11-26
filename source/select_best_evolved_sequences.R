#!/usr/bin/env Rscript
options(width=150)
library(tidyverse)

# Define infile
evolved_file = "intermediate/evolved.tab"

# Load data
evolved = read_tsv(evolved_file)

# Select the best sequences from each trajectory
best_sequences = evolved %>%
  group_by(Parameters, Direction, Sample) %>%
  slice_max(order_by=ifelse(Direction == "forward", Score, -Score), n=1)

# Save the table
write_tsv(best_sequences, "intermediate/best_evolved.tab")
