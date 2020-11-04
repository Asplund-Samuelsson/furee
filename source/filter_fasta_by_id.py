#!/usr/bin/python3
import sys

# Read input arguments
in_fasta  = sys.argv[1]
seqid_file  = sys.argv[2]
out_fasta = sys.argv[3]

# Load wanted sequence IDs
seqids = set()

for line in open(seqid_file):
    seqids.add(line.strip())

out_fasta = open(out_fasta, 'w')

# Iterate over FASTA, writing sequences that are wanted to outfile
wanted = False

for line in open(in_fasta):
    if line.startswith(">"):
        if line.lstrip(">").split()[0] in seqids:
            wanted = True
        else:
            wanted = False
    if wanted:
        out_fasta.write(line)

out_fasta.close()
