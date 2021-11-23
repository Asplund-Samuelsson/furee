import numpy as np

sequence_file = "data/Syn6803_P73922_FBPase.txt"

# Load starting sequence
with open(sequence_file) as s:
    starting_sequence = list(s.read().strip())

# Mutations
feng_positions = [
    1,
    164, 213, 215, 307,
    309, 314, 176, 200,
    102, 198, 131, 134,
    178, 29
]

feng_mutants = [
    'M',
    'A', 'A', 'A', 'A',
    'A', 'A', 'A', 'A',
    'A', 'H', 'A', 'A',
    'G', 'A'
]

km = [
    0.08,
    0.11, 0.08, 0.10, 0.24,
    0.21, 0.08, 3.20, 1.32,
    0.10, 0.17, 0.26, 0.50,
    0.61, 0.15
]

kcat = [
    10.5,
    2.3, 5.2, 1.2, 5.2,
    5.2, 2.6, 0.7, 0.63,
    0.7, 0.84, 1.2, 1.8,
    7.1, 21.3
]

# Make mutants and save tables
km_file = "data/FBPase_km.train.tab"
kcat_file = "data/FBPase_kcat.train.tab"

km_out = open(km_file, 'w')
kcat_out = open(kcat_file, 'w')

for m in range(len(feng_mutants)):
    # Assemble mutant
    mutant = starting_sequence[:feng_positions[m]-1] + \
    [feng_mutants[m]] + \
    starting_sequence[feng_positions[m]:]
    # Write km
    km_out.write("".join(mutant) + "\t" + str(km[m]) + "\n")
    # Write kcat
    kcat_out.write("".join(mutant) + "\t" + str(kcat[m]) + "\n")

km_out.close()
kcat_out.close()
