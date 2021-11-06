#!/usr/bin/env Rscript

# Read infile and outfile
args = commandArgs(trailingOnly=T)
infile  = args[1] # Sequence IDs and lengths infile
madnumber = as.numeric(args[2]) # Number of MADs
outfile = args[3] # Filtered sequence IDs outfile

# Load data
df = read.table(infile, sep="\t", stringsAsFactors=F, header=F)
colnames(df) = c("seqid", "length")

# Filter data
min_length = floor(median(df$length) - madnumber * mad(df$length))
max_length = ceiling(median(df$length) + madnumber * mad(df$length))

df_filt = subset(df, length <= max_length & length >= min_length)

nrow(df_filt) / nrow(df) # Calculate fraction of data kept

# Write filtered sequence IDs to outfile
write(df_filt$seqid, outfile)
