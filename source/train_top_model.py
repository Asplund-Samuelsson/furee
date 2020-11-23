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
    'infile',
    help='Text file with one sequence per line.'
)
parser.add_argument(
    'outdir', type=str,
    help='Output directory.'
)

# Optional input: Evotuning hyperparameters
parser.add_argument(
    '-v', '--validation', type=float, default=0.0,
    help='Fraction sequences to use for validation [0.0].'
)
parser.add_argument(
    '-e', '--epochs', type=int, default=20,
    help='Number of epochs to train for [20].'
)
parser.add_argument(
    '-b', '--batch', type=int, default=50,
    help='Batch size [50].'
)
parser.add_argument(
    '-s', '--step', type=float, default=1e-4,
    help='Step size/learning rate [1e-4].'
)
parser.add_argument(
    '-d', '--dumps', type=int, default=10,
    help='Epochs per parameter dump [10].'
)
parser.add_argument(
    '-m', '--method', type=str, default='random',
    help='Batching method ["random"].'
)
parser.add_argument(
    '-c', '--cpu', action='store_const', const='cpu', default='gpu',
    help='Use CPU instead of GPU.'
)
parser.add_argument(
    '-f', '--fraction', type=float, default=False,
    help='Use this fraction of input sequences.'
)

# Parse arguments
args = parser.parse_args()


# Load input sequences and associated values to predict
seqdata = [x.strip().split("\t") for x in open(seqdata_file).readlines()]
seqdata = [[x[0], float(x[1])] for x in seqdata]
sequences = [x[0] for x in seqdata]

# Load UniRep parameters
if parameter_dir:
    params = ju.utils.load_params(folderpath=parameter_dir)[0]
else:
    params = None

# Make representations for each input sequence
h_avg, h_final, c_final = ju.get_reps(sequences, params=params)

# Train top model
X = h_avg
y = np.array([x[1] for x in seqdata])

A = np.logspace(-6, 6, 13, base=10)

top_model = sklearn.linear_model.RidgeCV(alphas=A, normalize=True, cv=10)

top_model.fit(X, y)

top_model.predict(X)

# Save top model
