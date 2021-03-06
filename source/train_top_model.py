#!/usr/bin/env python3
import jax_unirep as ju
import numpy as np
import sklearn
import pickle
import argparse
import scipy

# Read arguments from the commandline
parser = argparse.ArgumentParser()

# Required input: Infile and project output (positional)
parser.add_argument(
    'infile',
    help='Tab-delimited file with one sequence-float pair per line.'
)
parser.add_argument(
    'outfile', type=str,
    help='File where pickled model is saved.'
)

# Optional input: Training parameters
parser.add_argument(
    '-p', '--parameters', type=str, default=None,
    help='Parameter directory for mLSTM.'
)

# Parse arguments
args = parser.parse_args()

seqdata_file = args.infile
parameter_dir = args.parameters
outfile = args.outfile

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
h_avg, _, _ = ju.get_reps(sequences, params=params)

# Select X and y for training
X = h_avg
y = np.array([x[1] for x in seqdata])

# Try logspaced alphas (regularization) between 1e-6 and 1e6
A = np.logspace(-6, 6, 13, base=10)

# Prepare a preliminary top model that does generalized cross-validation
top_model = sklearn.linear_model.RidgeCV(
    alphas=A, normalize=True, cv=None, store_cv_values=True
)

# Train the preliminary model
top_model.fit(X, y)

# Extract cross-validation values for the selected alpha level
base_cv = top_model.cv_values_[:,A==top_model.alpha_]

# Compare to higher alpha levels with t-test (p>=0.05)
p = scipy.stats.ttest_ind(top_model.cv_values_, base_cv, equal_var=False).pvalue

# Perform sparse refit (SR), i.e. select highest regularization alpha while
# ensuring that CV values are statistically equal to the RidgeCV-selected level
alpha_SR = max(A[p >= 0.05])

# Refit model with the stronger alpha
top_model_SR = sklearn.linear_model.Ridge(alpha=alpha_SR, normalize=True)
top_model_SR.fit(X, y)

# Save top model
with open(outfile, 'wb') as o:
    pickle.dump(top_model_SR, o)
