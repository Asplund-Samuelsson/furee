# Split sequences into batches of 64
mkdir intermediate/validation_batches
split -d -l 64 <(
  cat results/FBPase/evotuned/validation_sequences.txt \
  results/Rubisco/evotuned/validation_sequences.txt
) intermediate/validation_batches/batch_

# Get representations for each batch
ls intermediate/validation_batches/batch_* | while read Infile; do
  Outfile=`echo $Infile | sed -e 's/batch_/rep_fbpase_/'`
  python3 source/get_representations.py -p results/FBPase/evotuned/iter_final \
  $Infile $Outfile
done

ls intermediate/validation_batches/batch_* | while read Infile; do
  Outfile=`echo $Infile | sed -e 's/batch_/rep_rubisco_/'`
  python3 source/get_representations.py -p results/Rubisco/evotuned/iter_final \
  $Infile $Outfile
done

ls intermediate/validation_batches/batch_* | while read Infile; do
  Outfile=`echo $Infile | sed -e 's/batch_/rep_unirep_/'`
  python3 source/get_representations.py $Infile $Outfile
done

# Concatenate and gzip all representations
ls intermediate/validation_batches | grep batch | cut -f 2 -d _ | \
while read B; do
  # Paste sequences and FBPase representations
  paste intermediate/validation_batches/batch_${B} \
  intermediate/validation_batches/rep_fbpase_${B} | sed -e 's/^/FBPase\t/'
  # Paste sequences and Rubisco representations
  paste intermediate/validation_batches/batch_${B} \
  intermediate/validation_batches/rep_rubisco_${B} | sed -e 's/^/Rubisco\t/'
  # Paste sequences and UniRep representations
  paste intermediate/validation_batches/batch_${B} \
  intermediate/validation_batches/rep_unirep_${B} | sed -e 's/^/UniRep\t/'
done | pigz > intermediate/validation_reps.fbpase_rubisco.tab.gz

# Delete the intermediate files
# rm -rf intermediate/validation_batches

# Create seqid-to-sequence file
(
  cat results/FBPase/distance/train.filtered.fasta | sed -e 's/^>/\n>FBPase\t/';
  cat results/Rubisco/distance/train.filtered.fasta | sed -e 's/^>/\n>Rubisco\t/'
) | cut -f 1 -d \  | sed -e '/\t/ s/$/\t/' | \
tr -d "\n" | tr ">" "\n" | grep -v "^$" \
> intermediate/train.enzyme_seqid_seq.tab

# Perform PHATE analysis of validation sequence representations
source/phate_fbpase_rubisco.R
