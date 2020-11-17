#!/usr/bin/env python
import jax_unirep as ju
import sys
from random import shuffle
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

# Load sequences
sequences = [x.strip() for x in open(args.infile).readlines()]

# Randomize sequence order
shuffle(sequences)

# Select subset of sequences if desired
if args.fraction:
    break_point = int(len(sequences) * args.fraction)
    sequences = sequences[0:break_point]

# Set aside sequences for determining overfitting
if args.validation:
    # Split sequences into training set and validation set
    break_point = int(len(sequences) * (1 - args.validation))
    train_sequences = sequences[0:break_point]
    holdout_sequences = sequences[break_point:]
    # Save validation sequences
    with open("validation_sequences.txt", "w") as holdout_file:
        for seq in holdout_sequences:
            holdout_file.write(seq + "\n")
else:
    train_sequences = sequences
    holdout_sequences = None

# Perform evotuning
evotuned_params = ju.fit(
    params=None,
    sequences=train_sequences,
    n_epochs=args.epochs,
    batch_size=args.batch,
    step_size=args.step,
    holdout_seqs=holdout_sequences,
    batch_method=args.method,
    proj_name=args.outdir,
    epochs_per_print=args.dumps,
    backend=args.cpu,
)

ju.utils.dump_params(evotuned_params, args.outdir, step = 'final')
