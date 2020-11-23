# Split sequences into training and testing data
shuf data/dummy.sequence_height.tab | tee \
>(head -63 > data/dummy.train.tab) >(tail -n +64 > data/dummy.test.tab) \
> /dev/null

# Train top model with evotuned and original UniRep parameters
source/train_top_model.py -p results/evotuned/fbpase/iter_final \
data/dummy.train.tab intermediate/dummy.top_model.pkl

source/train_top_model.py \
data/dummy.train.tab intermediate/dummy.top_model.UniRep.pkl

# Make sequence-only files
cut -f 1 data/dummy.test.tab > intermediate/dummy.test.txt
cut -f 1 data/dummy.train.tab > intermediate/dummy.train.txt

# Make predictions with evotuned and original UniRep parameters
source/top_model_prediction.py -p results/evotuned/fbpase/iter_final \
intermediate/dummy.test.txt intermediate/dummy.top_model.pkl \
intermediate/dummy.test.predictions.tab

source/top_model_prediction.py -p results/evotuned/fbpase/iter_final \
intermediate/dummy.train.txt intermediate/dummy.top_model.pkl \
intermediate/dummy.train.predictions.tab

source/top_model_prediction.py \
intermediate/dummy.test.txt intermediate/dummy.top_model.UniRep.pkl \
intermediate/dummy.test.predictions.UniRep.tab

source/top_model_prediction.py \
intermediate/dummy.train.txt intermediate/dummy.top_model.UniRep.pkl \
intermediate/dummy.train.predictions.UniRep.tab

# Paste data together into one table
(
  echo "Data Sequence Height UniRep Evotuned" | tr " " "\t";
  paste data/dummy.train.tab \
  <(cut -f 2 intermediate/dummy.train.predictions.UniRep.tab) \
  <(cut -f 2 intermediate/dummy.train.predictions.tab) | sed -e 's/^/Train\t/';
  paste data/dummy.test.tab \
  <(cut -f 2 intermediate/dummy.test.predictions.UniRep.tab) \
  <(cut -f 2 intermediate/dummy.test.predictions.tab) | sed -e 's/^/Test\t/';
) > intermediate/top_model_evaluation.tab

# Investigate data with R
