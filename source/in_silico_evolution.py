#!/usr/bin/env python3
import jax_unirep as ju
import numpy as np
import sklearn
import pickle
import argparse
from copy import deepcopy
import pandas as pd
import os

# Read arguments from the commandline
parser = argparse.ArgumentParser()

# Required input: Infile and project output (positional)
parser.add_argument(
    'infile', type=str,
    help='Text file with one sequence on one line.'
)
parser.add_argument(
    'model', type=str,
    help='Pickled top model file or directory with top models.'
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
parser.add_argument(
    '-t', '--trust', type=int, default=7,
    help='Trust radius [7].'
)
parser.add_argument(
    '-r', '--reverse', action='store_true', default=False,
    help='Reverse direction of evolution.'
)
parser.add_argument(
    '-T', '--temperature', type=float, default=0.1,
    help='MCMC temperature; lower is slower [0.1].'
)
parser.add_argument(
    '-R', '--ratio', action='store_true', default=False,
    help='Use ratio instead of difference for sequence proposal rejection.'
)

# Parse arguments
args = parser.parse_args()

sequence_file = args.infile
parameter_dir = args.parameters
model_path = args.model
outfile = args.outfile
steps = args.steps
trust = args.trust
reverse = args.reverse
temperature = args.temperature
ratio = args.ratio

# Load target sequence
with open(sequence_file) as s:
    starting_sequence = s.read().strip()

# Load UniRep parameters
if parameter_dir:
    params = ju.utils.load_params(folderpath=parameter_dir)[1]
else:
    params = None

# If there is a single top model
if not os.path.isdir(model_path):

    # Load top model
    with open(model_path, 'rb') as i:
        top_model = [pickle.load(i)]
        top_model_names = ['score']

# If there are multiple top models in a directory
else:

    # Prepare list of top models
    top_model = []
    top_model_names = []

    # Load top models
    for m in os.listdir(model_path):
        i = open(os.path.join(model_path, m), 'rb')
        top_model.append(pickle.load(i))
        i.close()
        top_model_names.append(m)

# Define sequence scoring function
def scoring_func_forward(sequence: str):
    reps, _, _ = ju.get_reps(sequence, params=deepcopy(params))
    return np.array(
        [x.predict(reps) for x in top_model],
        # Use 128 bit float to avoid exp warning in is_accepted
        dtype=np.float128
    )

def scoring_func_reverse(sequence: str):
    reps, _, _ = ju.get_reps(sequence, params=deepcopy(params))
    return np.array(
        [1/x.predict(reps) for x in top_model],
        # Use 128 bit float to avoid exp warning in is_accepted
        dtype=np.float128
    )

# Patch the is_accepted function to work with multiple scores
def ia_patch_diff(best: float, candidate: float, temperature: float) -> bool:
    # Compare candidate based on difference in scores
    c = np.exp((candidate - best) / temperature)
    p = np.random.uniform(0, 1)
    return np.all(c >= p)

def ia_patch_ratio(best: float, candidate: float, temperature: float) -> bool:
    # Compare candidate based on ratio of scores
    c = np.exp(np.log(candidate / best) / temperature)
    p = np.random.uniform(0, 1)
    return np.all(c >= p)

# Use selected patch (difference or ratio of scores)
if not ratio:
    ju.sampler.is_accepted = ia_patch_diff
else:
    ju.sampler.is_accepted = ia_patch_ratio

# Select scoring function based on reverse evolution status
if reverse:
    scoring_func = scoring_func_reverse
else:
    scoring_func = scoring_func_forward

# Perform sampling
sampled_sequences = ju.sample_one_chain(
    starting_sequence, n_steps=steps, scoring_func=scoring_func,
    trust_radius=trust, is_accepted_kwargs = {'temperature':temperature}
)

# Extract the scores
scores = sampled_sequences.pop('scores')

# Invert scores for reverse evolution
if reverse:
    scores = 1 / scores

# Create data frame
sampled_seqs_df = pd.DataFrame(sampled_sequences)

# Add score columns
sampled_seqs_df = pd.concat([
    sampled_seqs_df,
    pd.DataFrame(
        dict(zip(
            [x.replace('.pkl', '') for x in top_model_names],
            scores
        ))
    )],
    axis=1
)

# Re-order columns
cols = sampled_seqs_df.columns.values
cols = list(cols[cols != 'accept']) + ['accept']

sampled_seqs_df = sampled_seqs_df[cols]

# Add step numbers
sampled_seqs_df['step'] = list(range(0, steps + 1))

# Save sampled sequences
sampled_seqs_df.to_csv(outfile, '\t', index=False)
