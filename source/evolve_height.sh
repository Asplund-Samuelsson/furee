# Evolve the distance from the root node of the Synechocystis sequence
mkdir intermediate/in_silico_evolution

for i in {1..20}; do

  # ...with original parameters

  # ...in the forward direction (increase distance)
  source/in_silico_evolution.py -s 50 -t 15 \
  data/Syn6803_P73922_FBPase.txt \
  intermediate/dummy.top_model.UniRep.pkl \
  intermediate/in_silico_evolution/evolved.unirep_forward.${i}.tab

  # ...in the reverse direction (decrease distance)
  source/in_silico_evolution.py -r -s 50 -t 15 \
  data/Syn6803_P73922_FBPase.txt \
  intermediate/dummy.top_model.UniRep.pkl \
  intermediate/in_silico_evolution/evolved.unirep_reverse.${i}.tab

  # ...with evotuned parameters
  # ...in the forward direction (increase distance)
  source/in_silico_evolution.py -s 50 -t 15 -p data/parameters/iter_final \
  data/Syn6803_P73922_FBPase.txt \
  intermediate/dummy.top_model.pkl \
  intermediate/in_silico_evolution/evolved.evotuned_forward.${i}.tab

  # ...in the reverse direction (decrease distance)
  source/in_silico_evolution.py -r -s 50 -t 15 -p data/parameters/iter_final \
  data/Syn6803_P73922_FBPase.txt \
  intermediate/dummy.top_model.pkl \
  intermediate/in_silico_evolution/evolved.evotuned_reverse.${i}.tab

done

# Collect the data (only accepted sequences)
(
  echo -e "Parameters\tDirection\tSample\tSequence\tScore\tIteration"
  grep -P "\tTrue\t" intermediate/in_silico_evolution/* | tr ":" "\t" \
  | sed -e 's/\./\t/' -e 's/\.tab\t/\t/' -e 's/\./\t/' | cut -f 2- \
  | sed -e 's/_/\t/' | cut -f 1-5,7
) > intermediate/evolved.tab

# Select the best sequences from each trajectory/sample chain
source/select_best_evolved_sequences.R
# Saves table "intermediate/best_evolved.tab"

# Estimate heights of each selected sequence
mkdir intermediate/height_estimation

tail -n +2 intermediate/best_evolved.tab | cut -f 4 | sort | uniq \
| parallel --no-notice --jobs 12 '
  source/estimate_height_of_sequence.sh {} {#}
'

# Gather output
(
  head -1 intermediate/height_estimation/1.seq_height.tab
  tail -qn +2 intermediate/height_estimation/*.seq_height.tab
) | cut -f 4- > intermediate/estimated_evolved_heights.tab

# Get original heights
head -q intermediate/in_silico_evolution/evolved.evotuned*.tab | grep "0$" \
| cut -f 2 | sort | uniq > intermediate/start_score.evotuned.txt

head -q intermediate/in_silico_evolution/evolved.unirep*.tab | grep "0$" \
| cut -f 2 | sort | uniq > intermediate/start_score.unirep.txt

# Analyze data
source/evaluate_evolved_heights.R
