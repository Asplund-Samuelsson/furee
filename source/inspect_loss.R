#!/usr/bin/env Rscript
library(tidyverse)
options(width=150)

# Define infile
evotuning_file = "intermediate/evotuning.tab"

# Load data
evotuning = read_tsv(evotuning_file)

# Reshape data
evotuning = evotuning %>% gather(Dataset, Loss, -Epoch)

# Plot it
gp = ggplot(evotuning, aes(x=Epoch, y=Loss, group=Dataset, colour=Dataset))
gp = gp + geom_line()
gp = gp + theme_bw()
gp = gp + theme(
  axis.ticks = element_line(colour="black"),
  axis.text = element_text(colour="black")
)
gp = gp + scale_y_log10()
gp = gp + annotation_logticks(sides="lr")
gp = gp + scale_colour_manual(values=c("#e08214", "#8073ac"))

ggsave("data/evotuning_loss.png", gp, w=6.5, h=3, dpi=200)
