# Split sequences into training and testing data
shuf data/FBPase_dummy.sequence_height.tab | tee \
>(head -63 > data/FBPase_dummy.train.tab) >(tail -n +64 \
> data/FBPase_dummy.test.tab) \
> /dev/null

# Train top model with evotuned and original UniRep parameters
source/train_top_model.py -p data/parameters/iter_final \
data/FBPase_dummy.train.tab \
intermediate/FBPase_dummy.top_model.pkl

source/train_top_model.py \
data/FBPase_dummy.train.tab intermediate/dummy.top_model.UniRep.pkl

# Make sequence-only files
cut -f 1 data/FBPase_dummy.test.tab > intermediate/dummy.test.txt
cut -f 1 data/FBPase_dummy.train.tab > intermediate/dummy.train.txt

# Make predictions with evotuned and original UniRep parameters
source/top_model_prediction.py -p data/parameters/iter_final \
intermediate/dummy.test.txt intermediate/dummy.top_model.pkl \
intermediate/dummy.test.predictions.tab

source/top_model_prediction.py -p data/parameters/iter_final \
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
  paste data/FBPase_dummy.train.tab \
  <(cut -f 2 intermediate/dummy.train.predictions.UniRep.tab) \
  <(cut -f 2 intermediate/dummy.train.predictions.tab) | sed -e 's/^/Train\t/';
  paste data/FBPase_dummy.test.tab \
  <(cut -f 2 intermediate/dummy.test.predictions.UniRep.tab) \
  <(cut -f 2 intermediate/dummy.test.predictions.tab) | sed -e 's/^/Test\t/';
) > intermediate/top_model_evaluation.tab

# Investigate data with R
source/evaluate_top_model.R
