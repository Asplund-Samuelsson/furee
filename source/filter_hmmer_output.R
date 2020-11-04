#!/usr/bin/env Rscript

# Read infile and outfile from command line
args = commandArgs(trailingOnly=T)
infile = args[1] # A hmmer tblout file
outfile = args[2] # A list of sequence IDs

# Load HMMER tblout file
indata = read.table(infile, sep="", header=F, fill=T, col.names=1:1000)
indata = indata[,1:19]

# Filter by column 8 (domain E-value)
indata = subset(indata, X5 < 0.01 & X8 < 0.03)

# Write sequence IDs to file
write.table(unique(indata[,"X1"]), outfile, row.names=F, col.names=F, quote=F)
