#!/usr/bin/env python3
import jax_unirep as ju
import numpy as np
import sklearn
import pickle
import argparse
from copy import deepcopy
import pandas as pd

model_file = "intermediate/dummy.top_model.pkl"
sequence_file = "data/Syn6803_P73922_FBPase.txt"
parameter_dir = "results/evotuned/fbpase/iter_final"
steps = 50

# Read arguments from the commandline
parser = argparse.ArgumentParser()

# Required input: Infile and project output (positional)
parser.add_argument(
    'infile', type=str,
    help='Text file with one sequence on one line.'
)
parser.add_argument(
    'model', type=str,
    help='Pickled top model file.'
)
parser.add_argument(
    'outfile', type=str,
    help='Tab-delimited file with sampled sequences and scores.'
)

# Optional input: Parameters
parser.add_argument(
    '-p', '--parameters', type=str, default=None,
    help='Parameter directory for mLSTM.'
)
parser.add_argument(
    '-s', '--steps', type=int, default=10,
    help='Number of MCMC steps [10].'
)

# Parse arguments
args = parser.parse_args()

sequence_file = args.infile
parameter_dir = args.parameters
model_file = args.model
outfile = args.outfile
steps = args.steps

# Load target sequence
with open(sequence_file) as s:
    starting_sequence = s.read().strip()

# Load top model
with open(model_file, 'rb') as i:
    top_model = pickle.load(i)

# Load UniRep parameters
if parameter_dir:
    params = ju.utils.load_params(folderpath=parameter_dir)[0]
else:
    params = None

# Define sequence scoring function
def scoring_func(sequence: str):
    reps, _, _ = ju.get_reps(sequence, params=deepcopy(params))
    return top_model.predict(reps)

# Perform sampling
sampled_sequences = ju.sample_one_chain(
    starting_sequence, n_steps=steps, scoring_func=scoring_func
)

sampled_seqs_df = pd.DataFrame(sampled_sequences)
sampled_seqs_df['step'] = list(range(0, steps + 1))

# Save sampled sequences
sampled_seqs_df.to_csv(outfile, '\t', index=False)
