#!/usr/bin/env Rscript
library(tidyverse)

infile = "intermediate/evotuning.tab"
outfile = "data/evotuning_loss.png"

# Read infile and outfile
args = commandArgs(trailingOnly=T)
infile  = args[1] # Evotuning loss development in tab-delimited format
outfile = args[2] # Plot of losses for training and validation datasets

# Load data
evotuning = read_tsv(infile)

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

ggsave(outfile, gp, w=6.5, h=3, dpi=200)
