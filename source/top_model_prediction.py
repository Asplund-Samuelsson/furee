#!/usr/bin/env python3
import jax_unirep as ju
import numpy as np
import sklearn
import pickle
import argparse

# Read arguments from the commandline
parser = argparse.ArgumentParser()

# Required input: Infile and project output (positional)
parser.add_argument(
    'infile', type=str,
    help='Text file with one sequence per line.'
)
parser.add_argument(
    'model', type=str,
    help='Pickled top model file.'
)
parser.add_argument(
    'outfile', type=str,
    help='Tab-delimited file with one sequence-float pair per line.'
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
model_file = args.model
outfile = args.outfile

# Load input sequences
sequences = [x.strip() for x in open(sequence_file).readlines()]

# Load top model
with open(model_file, 'rb') as i:
    top_model = pickle.load(i)

# Load UniRep parameters
if parameter_dir:
    params = ju.utils.load_params(folderpath=parameter_dir)[1]
else:
    params = None

# Make representations for each input sequence
h_avg, _, _ = ju.get_reps(sequences, params=params)

# Make prediction
prediction = top_model.predict(h_avg)

# Save predicted values
with open(outfile, 'w') as o:
    out = ["\t".join(x) for x in zip(sequences, [str(p) for p in prediction])]
    o.write("\n".join(out) + "\n")
