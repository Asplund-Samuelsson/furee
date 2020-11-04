#!/usr/bin/env python3
import sys

# Read input arguments
in_fasta  = sys.argv[1]
n_splits  = int(sys.argv[2])
out_prefix = sys.argv[3]

# Get all sequence IDs in input FASTA
seqids = set()
for line in open(in_fasta):
    if line.startswith(">"):
        seqids.add(line.lstrip(">").split()[0])

# Determine seqid sets to save to separate files
seq_sets = []
i = 0
# While there are sequence IDs...
while len(seqids) > 0:
    # Take one sequence ID
    seqid = seqids.pop()
    # Place it in one set
    try:
        seq_sets[i].add(seqid)
    except IndexError:
        seq_sets.append(set([seqid]))
    # Move on to the next set
    i = (i + 1) % n_splits

def write_ids_to_fasta(in_fasta, out_fasta, seqids):
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

# Write all sequence sets to separate files
for i in range(len(seq_sets)):
    out_fasta = out_prefix + ".split-" + str(i) + ".fasta"
    write_ids_to_fasta(in_fasta, out_fasta, seq_sets[i])
