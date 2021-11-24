#!/usr/bin/env python3
import numpy as np
import argparse

# Read arguments from the commandline
parser = argparse.ArgumentParser()

# Required input: Infile and project output (positional)
parser.add_argument(
    'infile', type=str,
    help='Text file with one sequence on one line.'
)
parser.add_argument(
    'outfile', type=str,
    help='Tab-delimited file with mutated sequences and scores.'
)

# Optional input: Parameters
parser.add_argument(
    '-d', '--distribution', type=str, default='uniform:0:1',
    help='Score sampling distribution type with params [uniform:0:1].'
)
parser.add_argument(
    '-m', '--mutations', type=int, default=1,
    help='Number of mutations per sequence [1].'
)
parser.add_argument(
    '-n', '--mutants', type=int, default=24,
    help='Number of mutants to produce [24].'
)

# Parse arguments
args = parser.parse_args()

sequence_file = args.infile
outfile = args.outfile
distribution = args.distribution
mutations = args.mutations
mutants = args.mutants

# Parse distribution specification
distribution = distribution.split(":")
distribution[1] = float(distribution[1])
distribution[2] = float(distribution[2])

# Load starting sequence
with open(sequence_file) as s:
    starting_sequence = list(s.read().strip())

# Make mutants and scores while writing to outfile
with open(outfile, 'w') as o:
    for i in range(mutants):
        # Determine positions to mutate
        positions = np.random.choice(
            range(0,len(starting_sequence)), mutations, replace=False
        )
        # Build up mutant sequence
        mutant = []
        for j in range(len(starting_sequence)):
            if j not in positions:
                mutant.append(starting_sequence[j])
            else:
                # Pick mutant amino acid that is different from current position
                mutant.append(np.random.choice(list(filter(
                    lambda x: x != starting_sequence[j], starting_sequence
                ))))
        # Create randomly sampled score
        if distribution[0] == "uniform":
            score = np.random.uniform(*distribution[1:])
        else:
            score = np.random.uniform(0, 1)
        # Write data to outfile
        o.write("".join(mutant) + "\t" + str(score) + "\n")
