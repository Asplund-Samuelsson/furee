#!/usr/bin/env Rscript
library(tidyverse)
library(phateR)
options(width=150)

# Define infiles
evolution_file = "intermediate/best_evolved.tab"
heights_file = "intermediate/estimated_evolved_heights.tab"
evostart_file = "intermediate/start_score.evotuned.txt"
unistart_file = "intermediate/start_score.unirep.txt"

# Load data
evolution = read_tsv(evolution_file)
heights = read_tsv(heights_file)
evostart = scan(evostart_file, numeric())
unistart = scan(unistart_file, numeric())

# Reshape data
evo_plot = inner_join(evolution, heights) %>%
  select(-Sequence) %>%
  mutate(Observed = Target_height/Query_height) %>%
  mutate(
    Start_score = ifelse(Parameters == "evotuned", evostart, unistart),
    Claimed = Score / Start_score
  ) %>%
  select(Parameters, Direction, Sample, Iteration, Claimed, Observed) %>%
  mutate(
    Parameters = ifelse(Parameters == "evotuned", "Evotuned", "UniRep"),
    Direction = str_to_sentence(Direction),
    Direction = factor(Direction, levels=rev(unique(Direction)))
  )

# Plot it
gp = ggplot(evo_plot, aes(x=Claimed, y=Observed, colour=Parameters))
gp = gp + geom_density_2d(alpha=0.3)
gp = gp + geom_abline(slope=1, intercept=0, color="grey")
gp = gp + geom_point()
gp = gp + facet_grid(~Direction, scales="free_x")
gp = gp + theme_bw()
gp = gp + theme(
  axis.text=element_text(colour="black"),
  axis.ticks=element_line(colour="black"),
  strip.background=element_blank(),
  aspect.ratio=1
)
gp = gp + scale_color_manual(values=c("#7fbf7b", "#af8dc3"))
gp = gp + ggtitle("Relative change in distance from root after evolution")

ggsave("data/evolution_evaluation.png", gp, w=6.5, h=3.5, dpi=200)
