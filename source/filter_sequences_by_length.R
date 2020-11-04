#!/usr/bin/env Rscript

# Read infile and outfile
args = commandArgs(trailingOnly=T)
infile  = args[1] # Sequence IDs and lengths infile
outfile = args[2] # Filtered sequence IDs outfile

# Load data
df = read.table(infile, sep="\t", stringsAsFactors=F, header=F)
colnames(df) = c("seqid", "length")

# Filter data
min_length = floor(mean(df$length) - 2*sd(df$length))
max_length = ceiling(mean(df$length) + 2*sd(df$length))

df_filt = subset(df, length <= max_length & length >= min_length)

nrow(df_filt) / nrow(df) # Calculate fraction of data kept

# Write filtered sequence IDs to outfile
write(df_filt$seqid, outfile)
