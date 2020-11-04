#!/usr/bin/env python

# Import modules
import sys

# First sequence has not been counted yet
seqname = None

# Read from standard input
for line in sys.stdin.readlines():
    # Clean up line
    line = line.strip()
    if line.startswith(">"):
        # Print previous sequence
        if seqname:
            print(seqname + "\t" + str(n))
        # Save name of current sequence
        seqname = line.split()[0].lstrip(">")
        # Reset counter
        n = 0
    else:
        # Add length to counter
        n = n + len(line)

# Print the last sequence
print(seqname + "\t" + str(n))
