# Split sequences into batches of 64
mkdir intermediate/validation_batches
split -d -l 64 data/validation_sequences.txt \
intermediate/validation_batches/batch_

# Get representations for each batch
ls intermediate/validation_batches/batch_* | while read Infile; do
  Outfile=`echo $Infile | sed -e 's/batch_/rep_evotuned_/'`
  source/get_representations.py -p data/parameters/iter_final \
  $Infile $Outfile
done

ls intermediate/validation_batches/batch_* | while read Infile; do
  Outfile=`echo $Infile | sed -e 's/batch_/rep_unirep_/'`
  source/get_representations.py $Infile $Outfile
done

# Concatenate and gzip all representations
cat intermediate/validation_batches/rep_evotuned_* | pigz \
> intermediate/validation_reps.evotuned.tab.gz

cat intermediate/validation_batches/rep_unirep_* | pigz \
> intermediate/validation_reps.unirep.tab.gz

# Delete the intermediate files
rm -rf intermediate/validation_batches

# Create seqid-to-sequence file
cat intermediate/train.filtered.fasta | cut -f 1 -d \  | sed -e '/^>/ s/$/\t/' \
| tr -d "\n" | tr ">" "\n" | grep -v "^$" \
> intermediate/train.seqid_seq.tab

# Perform PHATE analysis of validation sequence representations
source/phate_evaluation.R
