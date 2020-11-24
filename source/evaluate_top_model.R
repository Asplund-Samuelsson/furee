#!/usr/bin/env Rscript
library(tidyverse)
options(width=150)

# Define infiles
evaluation_file = "intermediate/top_model_evaluation.tab"

# Load data
evaluation = read_tsv(evaluation_file)

# Reshape
evaluation = evaluation %>%
  group_by(Data) %>%
  mutate(ID = 1:length(Data)) %>%
  ungroup() %>%
  select(-Sequence) %>%
  gather(Parameters, Predicted, -Data, -ID, -Height) %>%
  rename(Actual = Height)

# Determine the maximum height of data for plotting neatly
max_height = max(c(evaluation$Actual, evaluation$Predicted))

# Calculate root mean squared error
rmse = evaluation %>%
  group_by(Parameters, Data) %>%
  summarise(RMSE = sqrt(sum((Predicted - Actual)^2)/length(Data))) %>%
  mutate(
    Actual = ifelse(Parameters == "Evotuned", 0.39, 0.36),
    Predicted = 0.27,
    Label = paste(Parameters, "RMSE ≈", round(RMSE, 4))
  )

# Plot
gp = ggplot(evaluation, aes(x=Predicted, y=Actual, color=Parameters))
gp = gp + geom_abline(slope=1, intercept=0, color="grey")
gp = gp + geom_point(size=2, alpha=0.6, stroke=0)
gp = gp + geom_text(
  data=rmse, mapping=aes(label=Label), hjust=1
)
gp = gp + theme_bw()
gp = gp + scale_color_manual(values=c("#7fbf7b", "#af8dc3"), guide=F)
gp = gp + facet_grid(~Data)
gp = gp + theme(
  axis.ticks=element_line(color="black"),
  axis.text=element_text(color="black"),
  strip.background=element_blank(),
  aspect.ratio=1
)
gp = gp + xlim(0, round(max_height, 1)) + ylim(0, round(max_height, 1))
gp = gp + ggtitle("Distance from root of tree")

ggsave("data/top_model_evaluation.png", gp, w=6.5, h=4, dpi=200)
