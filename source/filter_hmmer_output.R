#!/usr/bin/env Rscript
library(tidyverse)
library(foreach)
library(doMC)
library(outliers)

# Read infile and outfile from command line
args = commandArgs(trailingOnly=T)
indir = args[1] # A directory with HMMER tblout files
outfile = args[2] # A list of sequence IDs

# Load HMMER tblout files
registerDoMC(8)
indata = bind_rows(
  foreach(
    f=grep("tblout", list.files(indir, full.names=T), value=T)
  ) %dopar% {
    read_tsv(
      pipe(
        paste(
          "grep -v '^#'", f, "| sed -e 's/ \\+/\t/g' | cut -f 1-19", sep=" "
        )
      ),
      col_names=F
    )
  }
)

# Filter by columns 5 (full sequence E-value) and 8 (best domain E-value)
indata = filter(indata, X5 < 0.01 & X8 < 0.03)

# Determine number of hits per query
qhits = indata %>% group_by(X3) %>% summarise(Hits = length(unique(X1)))

# Apply Hampel filter
qhits = filter(
  qhits,
  Hits < median(Hits) + 3*mad(Hits),
  Hits > median(Hits) - 3*mad(Hits)
)

# Write sequence IDs to file
write.table(
  unique(filter(indata, X3 %in% qhits$X3)$X1),
  outfile, row.names=F, col.names=F, quote=F
)
