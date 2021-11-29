# Create directory
mkdir -p results/diff_vs_ratio

# Iterate over 10 replicates
for i in {0..7}; do
  # Iterate over three temperatures
  for T in 0.3 0.1 0.03 0.01 0.003; do
      # Evolve based on difference of candidate and best sequence scores
      Outfile="results/diff_vs_ratio/${i}_${T}_Difference.tab"
      python3 source/in_silico_evolution.py \
        -s 200 -t 15 -T $T \
        -p results/FBPase/evotuned/iter_final \
        data/Syn6803_P73922_FBPase.txt \
        intermediate/top_models \
        $Outfile
      # Evolve based on ratio of candidate and best sequences scores
      Outfile="results/diff_vs_ratio/${i}_${T}_Ratio.tab"
      python3 source/in_silico_evolution.py \
        -s 200 -t 15 -T $T --ratio \
        -p results/FBPase/evotuned/iter_final \
        data/Syn6803_P73922_FBPase.txt \
        intermediate/top_models \
        $Outfile
  done
done
