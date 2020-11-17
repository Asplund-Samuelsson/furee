![alt text](furee.png "FBPase UniRep Enzyme Engineering")

# FBPase UniRep Enzyme Engineering

## About
Engineering of the Calvin cycle enzyme fructose-1,6-bisphosphatase/sedoheptulose-1,7-bisphosphatase (FBPase/SBPase) through [UniRep](https://github.com/churchlab/UniRep) machine learning and _in silico_ evolution.

## System requirements

Linux operating system (Tested on Ubuntu 18.04.5 LTS and 20.04.1 LTS)

bash 4.0 (Tested with 4.4.20(1)-release and 5.0.17(1)-release)

Python 3.7 (Tested with 3.7.6 and 3.8.3)

R ≥ 3.6.3 (Tested with 3.6.3)

GNU parallel 20161222 (Tested with 20161222)

seqmagick 0.6.2 (Tested with 0.6.2)

hmmer 3.1b2 (Tested with 3.1b2)

Python libraries: ...

R libraries: ...


## Installation

### 1. This repository

Download the FUREE repository from GitHub and enter the directory:
```
git clone https://github.com/Asplund-Samuelsson/furee.git

cd furee
```

### 2. UniProt database

Training sequences will be extracted from the UniProt database. Run these commands to download the necessary FASTA files for SwissProt and TrEMBL, constituting UniProt (may take several hours):

```
cd data/uniprot

wget ftp://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/complete/uniprot_sprot.fasta.gz

wget ftp://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/complete/uniprot_trembl.fasta.gz

zcat uniprot_sprot.fasta.gz uniprot_trembl.fasta.gz > uniprot.fasta

rm uniprot_sprot.fasta.gz uniprot_trembl.fasta.gz # Optional cleanup

cd ../..
```

### 3. NCBI taxonomy database

This analysis uses the NCBI taxonomy database to assign taxonomic classifications to UniProt sequences. Run these commands to download the necessary `names.dmp` and `nodes.dmp` files:

```
cd data/ncbi/taxonomy

wget https://ftp.ncbi.nlm.nih.gov/pub/taxonomy/taxdump.tar.gz

tar -zxvf taxdump.tar.gz names.dmp nodes.dmp

rm taxdump.tar.gz # Optional cleanup

cd ../../..
```

### 4. JAX-UniRep

The analysis uses the user-friendly JAX implementation of UniRep named [jax-unirep](https://github.com/ElArkk/jax-unirep). It may be installed from PyPI as described below (see the jax-unirep GitHub repository for more details):

```
pip install jax-unirep
```

To enable CUDA GPU support, you may need to install the correct JAX packages; see [instructions in the JAX repository](https://github.com/google/jax#pip-installation).

## Data

The Jackhmmer search for training sequences in UniProt begins with a set of known target sequence relatives. We obtain this set from KEGG orthologs K01086 and K11532 by following the instructions in this bash script:

```
source/get_FBPase_sequences.sh
```

...yielding this FASTA file with initial protein sequences:

```
data/kegg_uniprot.FBPase.fasta
```

## Method

Follow the steps in `furee.sh`.

## Author
Johannes Asplund-Samuelsson, KTH (johannes.asplund.samuelsson@scilifelab.se)
