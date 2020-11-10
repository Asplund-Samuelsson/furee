#!/usr/bin/env Rscript
library(tidyverse)

# Define infiles
levenshtein_file = "intermediate/train.standard_aa.LD.tab"
goodlength_file = "intermediate/train.length_filtered.txt"

# Load data
levenshtein = read_tsv(levenshtein_file, col_names=c("SeqA", "SeqB", "LD"))
goodlength = scan(goodlength_file, character())

# Filter Levenshtein distances to length-filtered sequences
levenshtein = filter(levenshtein, SeqA %in% goodlength, SeqB %in% goodlength)

# Investigate length distribution
# levenshtein$LD %>% hist(200)

# Set distance threshold
levenshtein = filter(levenshtein, LD <= 300)

# Write filtered sequence IDs to outfile
outfile = "intermediate/train.filtered.txt"
write(unique(c(levenshtein$SeqA, levenshtein$SeqB)), outfile)
