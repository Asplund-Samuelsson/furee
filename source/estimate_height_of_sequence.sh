#!/usr/bin/env bash

Sequence="MDSTLGLEIIEWVEQAAIASAKWMGKGEKNTADQVAVEAMRERMNKIHMRGRIVIGEGERDDAPMLYIGEEVGICTREDAKSFCNPDELVEIDIAVDPCEGTNLVAYGQNGSMAVLAISEKGGLFAAPDFYMKKLAAPPAAKGHVDIDKSATENLQILSDCLNRSIEELVVVVMDRPRHKELHQEIRNAGAMVRLISDGDVSASISCAFSGTNIHALMGIGAAPEGVIVAAKMRCLGGHFQGQLIKDPECVKTGLIGWSREGNLERLASMGIKNPYQVYNCEELWIGETVLFAACGINPGTLMEGVRFFHGGVRTQSLVISSQSSTDRFVDTVHMKESPKVIQLH"
ID="1"

Sequence=$1 # Sequence to estimate height for is the first argument
ID=$2 # ID for current process is the second argument

# Align sequence together with other Synechocystis sequences and make tree
(
  echo -e ">target\n${Sequence}"
  cat intermediate/train.cdhit_0.85.Synechocystis.fasta
) | mafft - | fasttreeMP > intermediate/height_estimation/${ID}.tree

# Estimate the height and additional data
source/height_of_sequence.R \
intermediate/height_estimation/${ID}.tree \
data/FireProt_Syn6803_ASR.tree \
target query "sp|P73922|FBSB_SYNY3" \
intermediate/height_estimation/${ID}.height.tab

# Add sequence to output
paste \
<(cat intermediate/height_estimation/${ID}.height.tab) \
<(echo -e "Sequence\n${Sequence}") \
> intermediate/height_estimation/${ID}.seq_height.tab
