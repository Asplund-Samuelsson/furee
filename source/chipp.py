#!/usr/bin/env python3

# Import modules
import sys

# Read from standard input
for line in sys.stdin.readlines():
    # Clean up line
    line = line.strip()
    if line.startswith(">"):
        # Save name of current cluster
        cluster = line.split()[1]
    else:
        # Split line on whitespace
        line = line.split()
        # Remove "at" element
        line = list(filter(lambda x: x != "at", line))
        # Extract the number of amino acids
        length = line[1].strip("a,")
        # Extract the sequence ID
        seqid = line[2].strip(">.")
        # Extract the sequence % identity
        percid = line[3].strip("%")
        # Print line
        print("\t".join([cluster, seqid, length, percid]))
