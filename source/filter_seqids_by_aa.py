#!/usr/bin/python3
import sys

# Read input arguments
in_fasta  = sys.argv[1]
outfile = sys.argv[2]

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

# Specify accepted amino acids
amino_acids = set(list("ACDEFGHIKLMNPQRSTVWY"))

# Iterate over FASTA, writing sequence IDs that are wanted to outfile
outfile = open(outfile, 'w')

for seq in fasta(in_fasta):
    if set(list(seq[1])).issubset(amino_acids):
        junk = outfile.write(seq[0] + "\n")

outfile.close()
