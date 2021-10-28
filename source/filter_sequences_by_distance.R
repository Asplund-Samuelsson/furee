#!/usr/bin/env Rscript
library(tidyverse)

# Read infiles and outfile from command line
args = commandArgs(trailingOnly=T)
levenshtein_file  = args[1] # File with Levenshtein distances to target
goodlength_file = args[2] # File with accepted length sequence IDs
outfile = args[3] # File with final filtered training sequence IDs

# Load data
levenshtein = read_tsv(levenshtein_file, col_names=c("SeqA", "SeqB", "LD"))
goodlength = scan(goodlength_file, character())

# Filter Levenshtein distances to length-filtered sequences
levenshtein = filter(levenshtein, SeqA %in% goodlength, SeqB %in% goodlength)

# Set distance threshold
levenshtein = filter(levenshtein, LD <= 300)

# Write filtered sequence IDs to outfile
write(unique(c(levenshtein$SeqA, levenshtein$SeqB)), outfile)
