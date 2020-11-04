#!/usr/bin/env python3
import sys
from Levenshtein import distance as LD

# Read input arguments
fasta_a  = sys.argv[1]
fasta_b  = sys.argv[2]
out_file = sys.argv[3]

# Generator object to turn fasta into iterator
class fasta(object):
    # Initialize fasta object
    def __init__(self, fasta_file):
        self.name = fasta_file # Name of fasta file
        self.file = open(self.name) # File object for fasta
        self.current_seqid = "" # Current sequence ID in iteration of fasta
        self.next_seqid = "" # Next sequence ID in iteration of fasta
        self.sequence = "" # Current sequence
        self.empty = False # Flag for finished fasta
        self.delivered = False # Flag for having delivered one sequence
    # Iteration function
    def __iter__(self):
        return self
    # Python3 compatibility
    def __next__(self):
        return self.next()
    # Function for returning a sequence
    def return_sequence(self):
        self.delivered = True
        return (self.current_seqid, self.sequence)
    # Grab next sequence
    def next(self):
        # Delivery of sequence has not been performed
        self.delivered = False
        # As long as delivery has not been performed, keep reading fasta file
        while not self.delivered:
            # If the current sequence does not match the next sequence
            if self.current_seqid != self.next_seqid:
                # Reset the sequence
                self.current_seqid = self.next_seqid
                self.sequence = ""
            # If fasta is finished, raise exception
            if self.empty:
                raise StopIteration()
            # Otherwise, grab next line
            try:
                line = next(self.file)
            # If FASTA is finished, set empty flag and return sequence
            except StopIteration:
                self.empty = True
                return self.return_sequence()
            # If there is a new sequence...
            if line.startswith(">"):
                # Extract the new sequence ID
                self.next_seqid = line.lstrip(">").split()[0]
                # If there is a current sequence ID...
                if self.current_seqid:
                    # Return the current sequence
                    return self.return_sequence()
            # If there is still the same sequence
            else:
                # Keep building it
                self.sequence = self.sequence + line.strip()

# Dictionary to store distances
distances = {}

# Connect to the two fasta files via the generator and calculate distances
for seq_a in fasta(fasta_a):
    for seq_b in fasta(fasta_b):
        distances[frozenset([seq_a[0], seq_b[0]])] = LD(seq_a[1], seq_b[1])

# Write distances to outfile
with open(out_file, 'w') as o_f:
    for d in distances.items():
        output = list(d[0])*(1+len(d[0])%2) + [str(d[1])]
        junk = o_f.write("\t".join(output) + "\n")
