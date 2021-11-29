![alt text](furee.png "Facilitating UniRep Enzyme Engineering")

# Facilitating UniRep Enzyme Engineering

Engineering of enzymes through [UniRep](https://github.com/churchlab/UniRep) machine learning and _in silico_ evolution, targeting calvin cycle enzymes fructose-1,6-bisphosphatase/sedoheptulose-1,7-bisphosphatase (FBPase/SBPase), ribulose-1,5-bisphosphate carboxylase/oxygenase (Rubisco), and more.

### Contents

1. [Overview](#overview)
2. [System requirements](#requirements)
3. [Installation](#installation)
4. [Usage](#usage)
5. [Exploring evotuning of FBPase](#exploring)
6. [Author](#author)

<a name="overview"></a>
## Overview

| ![alt text](data/furee_overview.png "Overview of the UniRep protein engineering workflow") |
| --- |
| **UniRep protein engineering promises computer-guided evolution using as few as 24 characterized proteins.** The workflow involves re-training an AI model with protein sequences closely related to the protein targeted for _in silico_ evolution (**A**). A regression top model utilizes the UniRep sequence representations to guide evolution and suggest improved sequence variants (**B**). |

<a name="requirements"></a>
## System requirements

### Hardware

Evotuning was performed on a GCP VM with two vCPUs, 13 GB RAM, and one NVIDIA Tesla T4 GPU with 16 GB VRAM. Other tasks were performed on Linux systems with 16 cores and 128 GB RAM (Ubuntu 18.04.5 LTS), and 12 cores, 32 GB RAM, and an NVIDIA RTX 2070 SUPER GPU with 8 GB VRAM (Ubuntu 20.04.3 LTS). Top model fitting and _in silico_ evolution ([Usage steps 4-6](#topmodel)) may be performed on a regular laptop.

### Software

<details>
<summary>Programs</summary>

| Software | Version | Tested version | Note |
| -------- | ------- | -------------- | --------- |
| Linux OS | | Ubuntu 18.04.5 LTS and 20.04.3 LTS | |
| Bash | 4.0 | 4.4.20, 5.0.17 | |
| Python | 3.7 | 3.7.6, 3.8.3 | |
| R | 3.6.3 | 3.6.3, 4.1.1 | |
| GNU parallel | 20161222 | 20161222 | |
| hmmer | 3.1b2 | 3.1b2 | |
| cd-hit | 4.8.1 | 4.8.1 | |
| pigz | 2.4 | 2.4 | Optional; Only needed for phateR scripts. |
| fasttreeMP | 2.1.11 | 2.1.11 | Optional; Not needed for [Usage](#usage). |

</details>

<details>
<summary>Python libraries</summary>

| Library | Version | Tested version | Note |
| ------- | ------- | -------------- | ---- |
| [BioPython](https://biopython.org/) | 1.76 | 1.76, 1.77 | |
| [python-levenshtein](https://pypi.org/project/python-Levenshtein/) | 0.12.0 | 0.12.0 | |
| [jax](https://github.com/google/jax) | 0.2.5 | 0.2.5, 0.2.24 | |
| [jax-unirep](https://github.com/ElArkk/jax-unirep) | 2.1.0 | 2.1.0 | |
| [numpy](https://numpy.org/) | 1.18.1 | 1.18.1, 1.18.5 | |
| [pandas](https://pandas.pydata.org/) | 0.25.3 | 0.25.3, 1.0.5 | |
| [scipy](https://scipy.org/) | 1.4.1 | 1.4.1, 1.5.0 | |
| [scikit-learn](https://scikit-learn.org/stable/) | 0.22.1 | 0.22.1, 0.23.1 | |

</details>

<details>
<summary>R libraries</summary>

| Library | Version | Tested version | Note |
| ------- | ------- | -------------- | ---- |
| [tidyverse](https://www.tidyverse.org/) | 1.3.1 | 1.3.1 | |
| [egg](https://cran.r-project.org/web/packages/egg/index.html) | 0.4.5 | 0.4.5 | |
| [doMC](https://cran.r-project.org/web/packages/doMC/index.html) | 1.3.7 | 1.3.7 | |
| [foreach](https://cran.r-project.org/web/packages/foreach/index.html) | 1.5.1 | 1.5.1 | |
| [phateR](https://github.com/KrishnaswamyLab/phateR) | 1.0.7 | 1.0.7 | Optional; Not needed for [Usage](#usage), only phateR scripts. |
| [phytools](https://cran.r-project.org/web/packages/phytools/index.html) | 0.7-90 | 0.7-90 | Optional; Not needed for [Usage](#usage). |
| [ggtree](https://bioconductor.org/packages/release/bioc/html/ggtree.html) | 3.0.4 | 3.0.4 | Optional; Not needed for [Usage](#usage). |

</details>

<a name="installation"></a>
## Installation

### Required components

#### This repository

Download the FUREE repository from GitHub and enter the directory (should take less than a minute, depending on the internet connection):
```
git clone https://github.com/Asplund-Samuelsson/furee.git

cd furee
```

#### JAX-UniRep

The analysis uses the user-friendly JAX implementation of UniRep named [jax-unirep](https://github.com/ElArkk/jax-unirep). It may be installed from PyPI as described below (see the jax-unirep GitHub repository for more details):

```
pip3 install jax-unirep
```

To enable CUDA GPU support, you may need to install the correct JAX packages; see [instructions in the JAX repository](https://github.com/google/jax).

### Optional components (required for evotuning)

This repository includes two evotuned models, for FBPase (`results/FBPase/evotuned/iter_final`) and Rubisco (`results/Rubisco/evotuned/iter_final`). Therefore the UniProt and NCBI taxonomy databases are only needed if you want to carry out [steps 1-3 in the Usage section](#usage).

#### UniProt database

Training sequences will be extracted from the UniProt database.

<details>
<summary>Install the full UniProt database (required for meaningful evotuning).</summary>

Run these commands to download the necessary FASTA files for SwissProt and TrEMBL, constituting UniProt (may take several hours):

```
cd data/uniprot

wget ftp://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/complete/uniprot_sprot.fasta.gz

wget ftp://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/complete/uniprot_trembl.fasta.gz

zcat uniprot_sprot.fasta.gz uniprot_trembl.fasta.gz > uniprot.fasta

rm uniprot_sprot.fasta.gz uniprot_trembl.fasta.gz # Optional cleanup

cd ../..
```

</details>

<details>
<summary>Install the SwissProt database (recommended for testing).</summary>

Run these commands to download the necessary FASTA file for SwissProt (should take less than a minute):

```
cd data/uniprot

wget ftp://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/complete/uniprot_sprot.fasta.gz

zcat uniprot_sprot.fasta.gz > uniprot.fasta

rm uniprot_sprot.fasta.gz # Optional cleanup

cd ../..
```

</details>


#### NCBI taxonomy database

This analysis uses the NCBI taxonomy database to assign taxonomic classifications to UniProt sequences.

<details>
<summary>Install the NCBI taxonomy database (recommended for testing).</summary>

Run these commands to download the necessary `names.dmp` and `nodes.dmp` files (should take less than a minute):

```
cd data/ncbi/taxonomy

wget https://ftp.ncbi.nlm.nih.gov/pub/taxonomy/taxdump.tar.gz

tar -zxvf taxdump.tar.gz names.dmp nodes.dmp

rm taxdump.tar.gz # Optional cleanup

cd ../../..
```

</details>

<a name="usage"></a>
## Usage

This guide describes how to get training data, carry out evotuning, fit a top model, and perform _in silico_ evolution using FUREE.

Evotuned models for FBPase and Rubisco are provided (`results/FBPase/evotuned/iter_final/` and `results/Rubisco/evotuned/iter_final/`), so if you wish you may skip the first three steps and go directly to [Fit a top model](#topmodel).

### 1. Obtain query sequences

The evotuning training data are UniProt sequences extracted through iterative JackHMMer searches with a small, but diverse, set of query sequences related to the protein to be evolved _in silico_. When preparing the training data in the next step, the input is a FASTA file with such query sequences.

#### Download KEGG orthologs

FUREE offers a programmatic approach to obtaining query sequence suggestions in the form of UniProt sequences representing KEGG orthologs (KOs). The program takes a comma-separated list of KOs (option `-k`) and/or a file with one KO per line (option `-i`) and saves the corresponding UniProt sequences to a FASTA file.

<details open>
<summary>FBPase:</summary>

```
source/uniprot_sequences_from_KO.sh \
  -i data/FBPase_KOs.txt \
  -o intermediate/FBPase_KOs.fasta
```

</details>

<details>
<summary>Rubisco:</summary>

```
source/uniprot_sequences_from_KO.sh \
  -k K01601 \
  -o intermediate/Rubisco_KOs.fasta
```

</details>

#### Reduce to cluster representatives

Since we want a manageable number of sequences as queries for the JackHMMer search, we need to reduce them to cluster representatives based on sequence identity.

<details open>
<summary>FBPase:</summary>

```
cd-hit -c 0.5 -n 2 \
  -i intermediate/FBPase_KOs.fasta \
  -o intermediate/FBPase_KOs.cdhit.fasta
```

</details>

<details>
<summary>Rubisco:</summary>

```
cd-hit -c 0.7 -n 5 \
  -i intermediate/Rubisco_KOs.fasta \
  -o intermediate/Rubisco_KOs.cdhit.fasta
```

</details>

#### Add _in silico_ evolution target

Finally, we add another query sequence, _e.g._ the target FBPase or Rubisco from _Synechocystis_, that we think might be particularly important.

<details open>
<summary>FBPase:</summary>

```
cat \
intermediate/FBPase_KOs.cdhit.fasta \
data/Syn6803_P73922_FBPase.fasta \
> intermediate/FBPase_queries.fasta
```

</details>

<details>
<summary>Rubisco:</summary>

```
cat \
intermediate/Rubisco_KOs.cdhit.fasta \
data/Syn6803_P54205_Rubisco.fasta \
> intermediate/Rubisco_queries.fasta
```

</details>

### 2. Prepare training data

The query sequences are used for JackHMMer searches against the UniProt sequence database and subsequently filtered (see table below for more details). We run a preparation script with the query sequences, the _in silico_ evolution target sequence, redundancy-filtering identity fraction, number of MADs defining allowed length range, the Levenshtein distance cutoff, and direct the output to a directory of choice.

**Note 1:** The training data preparation requires the UniProt database (`data/uniprot/uniprot.fasta`) and the NCBI taxonomy database (`names.dmp` and `nodes.dmp` in `data/ncbi/taxonomy/`). See [Installation](#installation).

**Note 2:** Because of JackHMMer, the preparation may take several days if searching the full UniProt database. For testing the preparation script it is recommended to use only SwissProt, which can be searched in just a few minutes. See [Installation](#installation).

<details open>
<summary>FBPase:</summary>

```
source/preparation.sh \
  intermediate/FBPase_queries.fasta \
  data/Syn6803_P73922_FBPase.fasta \
  1.0 1 300 \
  results/FBPase
```

</details>

<details>
<summary>Rubisco:</summary>

```
source/preparation.sh \
  intermediate/Rubisco_queries.fasta \
  data/Syn6803_P54205_Rubisco.fasta \
  0.99 1.5 400 \
  results/Rubisco
```

</details>

#### Steps of sequence identification and filtering

| # | Output | Description |
| --- | --- | --- |
| 1 | `jackhmmer/` | Use JackHMMer at default settings and a maximum of five iterations to find candidate UniProt sequences for evotuning. Require full sequence E-value < 0.01, best 1-domain E-value < 0.03, and number of hits within three median absolute deviations from the median (Hampel filter). |
| 2 | `cdhit/` | Use CD-HIT to make identified sequences unique. |
| 3 | `aa/` | Require that sequences consist of only standard amino acids. |
| 4 | `distance/` | Require that sequences show length within the defined number of median absolute deviations from the median, and then Levenshtein distance to target less than or equal to the defined value. |
| 5 | `taxonomy/` | Assess taxonomic distribution of training data. |
| 6 | `train.txt` | Save training sequences to file with one sequence per line. |
|   | `hits.txt` | Summarize UniProt annotations of training sequences. |

#### Training sequences

The final unique and filtered training sequences are stored in the `train.txt` file in the output directory.

<details>
<summary>FBPase:</summary>

```
results/FBPase/train.txt
```

| Taxonomic distribution and Levenshtein distance to target FBPase |
| --- |
| ![alt text](results/FBPase/taxonomy/taxonomic_distribution_of_train.png "Taxonomic distribution of FBPase training sequences") |

</details>

<details>
<summary>Rubisco:</summary>

```
results/Rubisco/train.txt
```

| Taxonomic distribution and Levenshtein distance to target Rubisco |
| --- |
| ![alt text](results/Rubisco/taxonomy/taxonomic_distribution_of_train.png "Taxonomic distribution of Rubisco training sequences") |

</details>

### 3. Evotune UniRep

The UniRep model weights, or parameters, must be re-trained, or evotuned, to the local evolutionary context of our _in silico_ evolution target sequence. To do se we supply our training sequences to the evotuning script.

**Note 1:** Evotuning should be run on a GPU. Training a model using the CPU (option `--cpu`) is very slow, and is even likely to stall, misbehave, or crash.

**Note 2:** If running this on GCP, it is necessary to run `screen` before to allow continued activity after disconnecting. Use Ctrl-A and Ctrl-D to detach the screen and keep it running.

<details open>
<summary>Evotune with FBPase training sequences.</summary>

```
python3 source/evotune.py \
  --epochs 100 --validation 0.05 \
  --step 1e-5 --batch 128 --dumps 1 \
  results/FBPase/train.txt \
  results/FBPase/evotuned &
```

</details>

<details>
<summary>Evotune with Rubisco training sequences.</summary>

```
python3 source/evotune.py \
  --epochs 100 --validation 0.05 \
  --step 1e-5 --batch 128 --dumps 1 \
  results/Rubisco/train.txt \
  results/Rubisco/evotuned &
```

</details>

#### Evotuning metadata

The evotuning produces various metadata, which are listed below.

| Output | Description |
| --- | --- |
| `validation_sequences.txt` | Validation sequences, one per line. |
| `evotuning.log` | Log with loss values and timings. |
| `evotuning.tab` | Training and validation losses in tab-delimited format. |
| `evotuning.png` | Plot of loss development across epochs.  |

#### Evotuned parameters

The evotuned model parameters are saved in a Python Pickle file.

<details>
<summary>FBPase:</summary>

```
results/FBPase/evotuned/iter_final/model_weights.pkl
```

![alt text](results/FBPase/evotuned/evotuning.png "FBPase training and validation loss over epochs")

</details>

<details>
<summary>Rubisco:</summary>

```
results/Rubisco/evotuned/iter_final/model_weights.pkl
```

![alt text](results/Rubisco/evotuned/evotuning.png "Rubisco training and validation loss over epochs")

</details>

#### How the model sees FBPase and Rubisco

The validation sequences were transformed into UniRep representations (1,900 floating point values per protein) and then subjected to [PHATE](https://github.com/KrishnaswamyLab/PHATE) dimensionality reduction to visualize the "sequence landscape" as seen by the original UniRep model, and the models trained with FBPase and Rubisco sequences. The following scripts made this possible:

```
source/phate_fbpase_rubisco.sh
source/get_representations.py
source/phate_fbpase_rubisco.R
```

| ![alt text](results/phate_fbpase_rubisco.png "FBPase and Rubisco sequences as seen by differently evotuned UniRep models") |
| --- |
| **FBPase and Rubisco sequences as seen by differently evotuned UniRep models.** Each point is one validation sequence. Rows indicate the type of enzyme, either FBPase or Rubisco, and columns indicate the type of parameters, _i.e._ parameters evotuned with FBPase or Rubisco sequences, or the original UniRep parameters. |

<a name="topmodel"></a>
### 4. Fit a top model

A top model leverages the protein representations produced by evotuned UniRep parameters to predict performance of novel sequences.

#### Top model training data

To fit a top model, it is necessary to provide sequences and associated values that are to be improved through directed evolution. Sequences and values should be saved in a tab-delimited format as in _e.g._ `data/FBPase_dummy.train.tab` (here we look only at the last 60 characters of each line to save space):

```
head -5 data/FBPase_dummy.train.tab | rev | cut -c 1-60 | rev
```

```
CGITPGTLMQGVQFFHNGARTQSLVISSQSRTARFVDTIHMFDKLEYVQLR	0.161198
CGITPGTLMEGVRFFHGGARTQSLVISSQSKTARFVDTVHMTDQPKTIQLK	0.078044
CGITPGTLMEGVRFFHGGARTQSLVISSQSKTARFVDTIHMFDQPKSIQLR	0.017744
CGITPGSLMEGVRFFGGGARTQSLVISNQSQTARFVDTIHLFDNVKSLQLR	0.173089
CGITPGTLMEGVRFFKGGARTQSLVISSQSQTARFVDTIHMFEEPKVLQLR	0.246331
```

#### Top model fitting

We fit the Ridge Regression Sparse Refit top model using evotuned UniRep parameters for the underlying representations.

<details open>
<summary>FBPase:</summary>

```
python3 source/train_top_model.py \
  -p results/FBPase/evotuned/iter_final \
  data/FBPase_dummy.train.tab \
  intermediate/FBPase_dummy.top_model.pkl
```

</details>

<details>
<summary>Rubisco:</summary>

```
python3 source/train_top_model.py \
  -p results/Rubisco/evotuned/iter_final \
  data/Rubisco_dummy.train.tab \
  intermediate/Rubisco_dummy.top_model.pkl
```

</details>

For additional options, refer to the help:

```
python3 source/train_top_model.py --help
```

### 5. Make predictions with the top model

Predictions with an already fitted top model can be made on sequences in a file with one sequence per line.

<details open>
<summary>FBPase:</summary>

```
fold -w 80 -s data/Syn6803_P73922_FBPase.txt
```

```
MDSTLGLEIIEVVEQAAIASAKWMGKGEKNTADQVAVEAMRERMNKIHMRGRIVIGEGERDDAPMLYIGEEVGICTREDA
KSFCNPDELVEIDIAVDPCEGTNLVAYGQNGSMAVLAISEKGGLFAAPDFYMKKLAAPPAAKGHVDIDKSATENLKILSD
CLNRSIEELVVVVMDRPRHKELIQEIRNAGARVRLISDGDVSAAISCAFSGTNIHALMGIGAAPEGVISAAAMRCLGGHF
QGQLIYDPEVVKTGLIGESREGNLERLASMGIKNPDQVYNCEELACGETVLFAACGITPGTLMEGVRFFHGGVRTQSLVI
SSQSSTARFVDTVHMKESPKVIQLH
```

```
python3 source/top_model_prediction.py \
  -p results/FBPase/evotuned/iter_final \
  data/Syn6803_P73922_FBPase.txt \
  intermediate/FBPase_dummy.top_model.pkl \
  results/FBPase/Syn6803_P73922_FBPase.prediction.tab
```

The prediction for FBPase is expected to be `0.16359496894461598`.

</details>

<details>
<summary>Rubisco:</summary>

```
fold -w 80 -s data/Syn6803_P54205_Rubisco.txt
```

```
MVQAKAGFKAGVQDYRLTYYTPDYTPKDTDLLACFRMTPQPGVPAEEAAAAVAAESSTGTWTTVWTDNLTDLDRYKGRCY
DLEAVPNEDNQYFAFIAYPLDLFEEGSVTNVLTSLVGNVFGFKALRALRLEDIRFPVALIKTFQGPPHGITVERDKLNKY
GRPLLGCTIKPKLGLSAKNYGRAVYECLRGGLDFTKDDENINSQPFMRWRDRFLFVQEAIEKAQAETNEMKGHYLNVTAG
TCEEMMKRAEFAKEIGTPIIMHDFFTGGFTANTTLARWCRDNGILLHIHRAMHAVVDRQKNHGIHFRVLAKCLRLSGGDH
LHSGTVVGKLEGERGITMGFVDLMREDYVEEDRSRGIFFTQDYASMPGTMPVASGGIHVWHMPALVEIFGDDSCLQFGGG
TLGHPWGNAPGATANRVALEACVQARNEGRNLAREGNDVIREACRWSPELAAACELWKEIKFEFEAMDTL
```

```
python3 source/top_model_prediction.py \
  -p results/Rubisco/evotuned/iter_final \
  data/Syn6803_P54205_Rubisco.txt \
  intermediate/Rubisco_dummy.top_model.pkl \
  results/Rubisco/Syn6803_P54205_Rubisco.prediction.tab
```

The prediction for Rubisco is expected to be `0.1516921772674731`.

</details>

For additional options, refer to the help:

```
python3 source/top_model_prediction.py --help
```

### 6. Perform _in silico_ evolution

The _in silico_ evolution is carried out using a set of evotuned parameters, a top model, and one starting sequence.

<details open>
<summary>FBPase:</summary>

```
python3 source/in_silico_evolution.py \
  -s 50 -t 15 \
  -p results/FBPase/evotuned/iter_final \
  data/Syn6803_P73922_FBPase.txt \
  intermediate/FBPase_dummy.top_model.pkl \
  results/FBPase/Syn6803_P73922_FBPase.evolved.tab
```

</details>

<details>
<summary>Rubisco:</summary>

```
python3 source/in_silico_evolution.py \
  -s 50 -t 15 \
  -p results/Rubisco/evotuned/iter_final \
  data/Syn6803_P54205_Rubisco.txt \
  intermediate/Rubisco_dummy.top_model.pkl \
  results/Rubisco/Syn6803_P54205_Rubisco.evolved.tab
```

</details>

The output tab-delimited file contains evolved sequences (column `sequences`), predicted values for each sequence (`scores`), status of acceptance for the next iteration in the evolution algorithm (`accept`), and the step (`step`).

For additional options, refer to the help:

```
python3 source/in_silico_evolution.py --help
```

#### Using multiple top models

We try to use multiple top models to guide the _in silico_ evolution by extending the function in JAX-UniRep that decides whether a sequence is accepted (`is_accepted`) to an arbitrary number of scores.

##### Collecting more data for more top models

First we create tables with mutant data for 15 _Synechocystis_ FBPase sequences from [Feng _et al._ 2013](https://doi.org/10.1111/febs.12657):

```
python3 source/feng_mutants.py
```

```
data/FBPase_km.train.tab
data/FBPase_kcat.train.tab
```

Then we train three top models (tree height, km, and kcat):

```
mkdir intermediate/top_models

python3 source/train_top_model.py \
  -p results/FBPase/evotuned/iter_final \
  data/FBPase_dummy.train.tab \
  intermediate/top_models/height.pkl

python3 source/train_top_model.py \
  -p results/FBPase/evotuned/iter_final \
  --max_alpha 3 \
  data/FBPase_km.train.tab \
  intermediate/top_models/km.pkl

python3 source/train_top_model.py \
  -p results/FBPase/evotuned/iter_final \
  --max_alpha 3 \
  data/FBPase_kcat.train.tab \
  intermediate/top_models/kcat.pkl
```

**Note:** It might be necessary to adjust the regularization alpha range to not over-regularize the top model. This was done for K<sub>m</sub> and k<sub>cat</sub> values in this example by capping regularization at alpha 10<sup>3</sup> instead of the default 10<sup>6</sup>.

##### Performing _in silico_ evolution with multiple top models

Finally, we may perform _in silico_ evolution using three top models simultaneously:

```
python3 source/in_silico_evolution.py \
  -s 500 -t 15 -T 0.001 \
  -p results/FBPase/evotuned/iter_final \
  data/Syn6803_P73922_FBPase.txt \
  intermediate/top_models \
  results/FBPase/Syn6803_P73922_FBPase.multi_evolved.tab
```

**Note 1:** Numpy might report `RuntimeWarning: overflow encountered in exp` in the `is_accepted` function during the MCMC sampling. This should be fine as it is associated with raising _e_ to the power of a large negative number and will yield `0.0`, which is adequate.

**Note 2:** To make the evolution across multiple top models more even, it might be necessary to modify the MCMC _temperature_ (`-T`) and the number of _steps_ (`-s`).

With some shell code we may take a look at the accepted sequences in the output table, cutting off each column for convenience:

```
(
  head -1 results/FBPase/Syn6803_P73922_FBPase.multi_evolved.tab
  paste \
    <(
      grep True results/FBPase/Syn6803_P73922_FBPase.multi_evolved.tab | \
      awk '{OFS="\t"} {for(i=1;i<=NF;i++) $i=substr($i,1,42)}1' | cut -f 1
    ) \
    <(
      grep True results/FBPase/Syn6803_P73922_FBPase.multi_evolved.tab | \
      awk '{OFS="\t"} {for(i=1;i<=NF;i++) $i=substr($i,1,6)}1' | cut -f 2-
    )
) | column -tn -s $'\t'
```

```
sequences                                   km      height  kcat    accept  step
MDSTLGLEIIEVVEQAAIASAKWMGKGEKNTADQVAVEAMRE  0.4403  0.1635  4.5727  True    0
MDSTLGLEIIEVVEQAAIASAKWMGKGEKNTADQVAVEAMRE  0.4416  0.1649  4.7796  True    5
MDSTLGLEIIEVVEQAAIASAKWMGKGEKNTADQVAVEAMRE  0.4712  0.1672  4.9850  True    13
MDSTLGLEIIEVVEQAAIASAKWMGKGEKNTADQVAVEAMRE  0.4919  0.1692  5.0271  True    42
MDSTLGLEIIEVVEQAAIASAKWMGKGEKNTADQVAVEAMRE  0.4958  0.1707  5.0537  True    56
MDSTLGLEIIEVVEQAAIASAKWMGKGEKNTADQVAVEAMRE  0.5016  0.1710  5.0873  True    98
MDSTLGLEIIEVVEQAAIASAKWMGKGEKNTADQVAVEAMRE  0.5075  0.1761  5.1062  True    116
MDSTLGLEIIEVVEQAAIASAKWMGKGEKNTADQVAVEAMRE  0.5281  0.1762  5.2091  True    148
MDSTLGLEIIEVVEQAAIASAKWMGKGEKNTADQVAVEAMRE  0.5307  0.1778  5.2345  True    152
MDSTLGLEIIEVVEQAAIASAKWMGKGEKNTADQVAVEAMRE  0.5307  0.1778  5.2345  True    153
MDSTLGLEIIEVVEQAAIASAKWMGKGEKNTADQVAVEAMIE  0.5476  0.1895  5.2951  True    154
MDSTLGLEIIEVVEQAAIASAKWMGFGEKNTADQVAVEAMIE  0.5501  0.2217  5.9309  True    161
MDSTLGLEIIEVVEQAAIASAKWMGFGEKNTADQVAVEAMIE  0.5507  0.2214  6.0149  True    166
MDSTLGLEIIEVVEQAAIASAKWMGFGEKNTADQVAVEAMIE  0.5554  0.2230  6.0231  True    216
MDSTLGLEIIEVVEQAAIASAKWMGFGEKNTADQVAVEAMIE  0.5572  0.2255  6.0607  True    233
MDSTLGLEIIEVVEQAAIASAKWMGFGEKNTADQVAVEAMIE  0.5673  0.2363  6.0729  True    259
MDSTLGLEIIEVVEQAAIASAKWMGFGEKNTADQVAVEAMIE  0.5675  0.2394  6.0828  True    350
```

**Note 1:** There are R41I and K26F mutations at steps 154 and 161.

**Note 2:** The first sequence is the wildtype _Synechocystis_ FBPase. It is supposed to have a K<sub>m</sub> of 0.08 and a k<sub>cat</sub> of 10.5, so these top models are clearly performing suboptimally.

##### Investigating the score comparison method for multiple top models

Comparing the score(s) of a proposed mutated sequence with the score(s) of the current best sequence is by default done by looking at the difference. This should be fine regardless of score magnitude when using a single score, but might be biasing the evolution progress under multiple scores of different magnitudes. Specifically, even a small fractional reduction in score of a higher magnitude would tend to generate more values close to zero in the _is_accepted_ function (raises _e_ to the power of the difference divided by the temperature). Values close to zero are unlikely to be higher than the randomly sampled value between 0 and 1, which is required for acceptance. In other words, slight score reductions for high magnitude scores are more likely to be rejected than those for low magnitude scores. Therefore the option to use a ratio for comparison (option `--ratio`, `-R`) instead of the difference was introduced.

To investigate the effect of difference and ratio comparison methods, as well as different temperature settings, multiple _in silico_ evolution runs were carried out. Eight replicate _in silico_ evolution chains were performed over 200 steps, with temperatures 0.003, 0.01, 0.03, 0.1, and 0.3, using difference or ratio as the comparison method:

```
bash source/diff_vs_ratio.sh
```

The results (`results/diff_vs_ratio/`) were visualized using R:

```
Rscript source/diff_vs_ratio.R
```

| ![alt text](results/diff_vs_ratio.png "") |
| --- |
| **Effect of different comparison methods and temperatures (T) on _in silico_ evolution trajectories.** Eight replicates per setting (temperature and comparison method) are shown by transparent lines. The mean of the current best sequences at each step is shown by opaque lines. |

<a name="exploring"></a>
## Exploring evotuning of FBPase

Evotuning using FBPase sequences was performed and evaluated in order to get acquainted with the JAX-UniRep framework and develop the tools in this repository. The steps to acquire example FBPase sequences and then evotune the UniRep model are described in `source/fbpase_evotuning_example.sh`.

**Note:** The analysis described below used an earlier version of JAX-UniRep and FUREE, and may be incompatible with the current versions.

### Jackhmmer reference sequences

The Jackhmmer search for training sequences in UniProt begins with a set of known target sequence relatives. We obtain this set from KEGG orthologs K01086 and K11532 by following the instructions in this bash script:

```
source/get_FBPase_sequences.sh
```

...yielding this FASTA file with initial reference protein sequences:

```
data/kegg_uniprot.FBPase.fasta
```

### Acquisition of example sequences

Jackhmmer was used to find 99,327 example sequences in the UniProt database. These sequences were mostly bacterial.

![alt text](data/taxonomic_distribution_of_train.png "Taxonomic distribution and distance to Synechocystis FBPase of training sequences")

### Training

The evotuning held out 4,967 sequences for validation and optimized parameters using the remaining 94,360 sequences. The losses reported by the JAX-UniRep _fit_ function for the training and validation sequences were plotted for 100 epochs of training with learning rate 1e-5 and batch size 128. The final iteration weights were accepted for future use since overfitting was not evident.

![alt text](data/evotuning_loss.png "Loss for training and validation sequences during evotuning")

### Evaluation of a top model

#### Ancestral sequences and failed dummy data

A set of dummy stability (_T<sub>m</sub>_) values were generated to facilitate development of the top model and _in silico_ evolution scripts. First, a phylogenetic tree was constructed based on 63 UniProt FBPase sequences (>85% identity) including the sequence in _Synechocystis_ sp. PCC 6803. Ancestral sequence reconstruction was performed using the [FireProt-ASR server](http://loschmidt.chemi.muni.cz/fireprotasr/). Changes in _T<sub>m</sub>_ were sampled going from the root sequence (_T<sub>m</sub>_ = 80°C) assuming decreasing stability with a target of _T<sub>m</sub>_ = 55°C at the furthest tip of the tree. The process was carried out as described in these scripts:

```
source/generate_dummy_Tm_data.sh
source/generate_dummy_ancestral_Tm.R
```

...finally yielding this table of 125 sequence-to-dummy-stability associations:

```
data/dummy.sequence_Tm.tab
```

...which represents typical input for training a top model.

The dummy _T<sub>m</sub>_ values are visualized in `data/dummy_ancestral_Tm_on_tree.pdf`. Unfortunately, it turned out that the dummy stability values generated were purely noise and could not be used for development of the top model.

#### Better luck with tree height values

Instead of the failed stability values, the tree height (distance from the root) of each node (sequence) was used as detailed in these scripts:

```
source/evaluate_top_model.sh
source/evaluate_top_model.R
```

...that generated and evaluated the following height data:

```
data/FBPase_dummy.train.tab
data/FBPase_dummy.test.tab
```

#### Top model performance

Splitting the set of ancestral and contemporary sequences into 63 training sequences and 62 testing sequences allowed development of a Ridge regression sparse refit (SR) top model used to predict height in the phylogenetic tree. The top model showed test RMSE ≈ 0.0339 using original UniRep mLSTM parameters and test RMSE ≈ 0.0263 using evotuned parameters.

![alt text](data/top_model_evaluation.png "Evaluation of top model using 125 FBPase sequences")

### Evaluation of sequence landscape

The validation sequences were transformed into representations using the original UniRep parameters as well as the freshly evotuned FBPase-specific parameters. The representations were in turn used to visualize the sequence landscape using [PHATE](https://github.com/KrishnaswamyLab/PHATE). The evotuned landscape was distinct from the original UniRep landscape; Possibly smoother and hopefully more information rich.

![alt text](data/phate_evaluation.png "Evaluation of evotuned FBPase sequence landscape")

### Evaluation of _in silico_ evolution potential

The _Synechocystis_ sp. PCC 6803 FBPase sequence was subjected to _in silico_ evolution (trust radius 15, 50 steps) guided by the evotuned mLSTM and the top model fitted on tree height values. Subsequently, the 80 best evolved sequences were separately aligned with the original 63 example sequences from "Evaluation of a top model". Trees were then constructed to estimate the change in tree height of the evolved sequences. This showed that the evotuned parameters lead to stronger evolution in the forward direction, and rightfully made more conservative claims for evolution in the reverse direction (which appeared to be impossible).

![alt text](data/evolution_evaluation.png "Evaluation of evotuned in silico FBPase evolution")

### Visualization of example FBPase representations

Representations were obtained for five FBPase sequences using original and evotuned UniRep parameters. The sequences are _Oligotropha carboxidovorans_ OM5 [_cbbF_](https://www.kegg.jp/dbget-bin/www_bget?ocg:OCA5_pHCG300410) and [_glpX_](https://www.kegg.jp/dbget-bin/www_bget?ocg:OCA5_c20090), _Ralstonia eutropha_ H16 [_cbbF2_](https://www.kegg.jp/dbget-bin/www_bget?reh:H16_B1390) and [_fbp_](https://www.kegg.jp/dbget-bin/www_bget?reh:H16_A0999), and _Synechocystis_ sp. PCC 6803 FBPase. The 1,900 representation values were ordered and plotted so that large standard deviations were located to the center of one 38 by 50 pixel image per sequence.

![alt text](data/representation_photos.png "A few FBPases viewed through the UniRep lens")

<a name="author"></a>
## Author

Johannes Asplund-Samuelsson (johannes.aspsam@gmail.com)
