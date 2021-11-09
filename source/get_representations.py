#!/usr/bin/env python3
import jax_unirep as ju
import numpy as np
import argparse

# Read arguments from the commandline
parser = argparse.ArgumentParser()

# Required input: Infile and project output (positional)
parser.add_argument(
    'infile', type=str,
    help='Text file with one sequence per line.'
)
parser.add_argument(
    'outfile', type=str,
    help='Tab-delimited file with sequence representations.'
)

# Optional input: Training parameters
parser.add_argument(
    '-p', '--parameters', type=str, default=None,
    help='Parameter directory for mLSTM.'
)

# Parse arguments
args = parser.parse_args()

sequence_file = args.infile
parameter_dir = args.parameters
outfile = args.outfile

# Load input sequences
sequences = [x.strip() for x in open(sequence_file).readlines()]

# Load UniRep parameters
if parameter_dir:
    params = ju.utils.load_params(folderpath=parameter_dir)[1]
else:
    params = None

# Make representations for each input sequence
h_avg, _, _ = ju.get_reps(sequences, params=params)

# Save representations
with open(outfile, 'w') as o:
    np.savetxt(o, h_avg, delimiter="\t")
