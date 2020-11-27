#!/usr/bin/env Rscript
library(tidyverse)
options(width=150)

# Define infiles
seqidseq_file = "intermediate/example_fbpase.seqid_seq.tab"
evoreps_file = "intermediate/example_fbpase_evoreps.tab"
unireps_file = "intermediate/example_fbpase_unireps.tab"
seqs_file = "intermediate/example_fbpase.txt"

# Load data
seqidseq = read_tsv(seqidseq_file, col_names=c("identifier", "Sequence"))
evoreps = read_tsv(evoreps_file, col_names=F)
unireps = read_tsv(unireps_file, col_names=F)
seqs = scan(seqs_file, character())

# Get sequences in correct order
seqidseq = seqidseq %>%
  right_join(tibble(Sequence=seqs, Order=1:length(seqs))) %>%
  arrange(Order)

# Reformat representations for plotting as "photos"
reps = bind_rows(
  unireps %>%
    mutate(Sequence = seqs) %>%
    inner_join(seqidseq) %>%
    select(-Sequence, -Order) %>%
    gather(Feature, Value, -identifier) %>%
    mutate(Parameters = "UniRep"),
  evoreps %>%
    mutate(Sequence = seqs) %>%
    inner_join(seqidseq) %>%
    select(-Sequence, -Order) %>%
    gather(Feature, Value, -identifier) %>%
    mutate(Parameters = "Evotuned")
)

# Make better label
reps = reps %>%
  mutate(
    Label = case_when(
      identifier == "Oligotropha_glpX_FBPase" ~ "Oligotropha glpX",
      identifier == "Oligotropha_cbbF_FBPase" ~ "Oligotropha cbbF",
      identifier == "Ralstonia_FBPase" ~ "Ralstonia fbp",
      identifier == "Ralstonia_cbbF2_FBPase" ~ "Ralstonia cbbF2",
      identifier == "sp|P73922|FBSB_SYNY3" ~ "Synechocystis"
    )
  )

# Create position and order it by average value
reps = reps %>% mutate(Position = as.integer(str_replace(Feature, "X", "")) - 1)

quadrant = bind_rows(lapply(
      0:18,
      function(l){
        distinct(
          bind_rows(lapply(0:l, function(o){tibble(X=c(l,l-o), Y=c(l-o,l))}))
        ) %>% arrange(X+Y)
      }
  )) %>%
  bind_rows(tibble(X = rep(0:18, 25-19), Y = rep(19:24, 19, each=T))) %>%
  mutate(Order = 0:(1900/4-1))

mean_value = reps %>%
  group_by(Position) %>%
  summarise(SD = sd(Value), Value = mean(Value)) %>%
  mutate(
    Value_order = rank(Value)-1,
    Quadrant = case_when(
      (Value_order >= 950) & ((Value_order %% 2) == 0) ~ 1,
      (Value_order >= 950) & ((Value_order %% 2) != 0) ~ 2,
      (Value_order < 950) & ((Value_order %% 2) == 0) ~ 3,
      (Value_order < 950) & ((Value_order %% 2) != 0) ~ 4
    )
  ) %>%
  group_by(Quadrant) %>%
  mutate(Order = rank(-SD) - 1) %>%
  inner_join(quadrant) %>%
  mutate(
    X = case_when(
      Quadrant == 1 ~ 18 - X,
      Quadrant == 2 ~ X + 19,
      Quadrant == 3 ~ 18 - X,
      Quadrant == 4 ~ X + 19
    ),
    Y = case_when(
      Quadrant == 1 ~ 24 - Y,
      Quadrant == 2 ~ 24 - Y,
      Quadrant == 3 ~ Y + 25,
      Quadrant == 4 ~ Y + 25
    )
  )


# Determine x and y position of feature
reps = reps %>% inner_join(select(mean_value, Position, X, Y))

# Plot it
gp = ggplot(reps, aes(x=X, y=Y, fill=Value))
gp = gp + geom_tile()
gp = gp + facet_grid(Parameters ~ Label)
gp = gp + theme_bw()
gp = gp + theme(
  axis.text=element_blank(),
  axis.title=element_blank(),
  axis.ticks=element_blank(),
  strip.background=element_blank(),
  panel.grid=element_blank(),
  panel.border=element_blank()
)
gp = gp + scale_fill_distiller(palette="PuOr")
gp = gp + coord_equal()
gp = gp + scale_y_reverse()

# Save as PNG
ggsave("data/representation_photos.png", gp, w=6.5, h=3.1, dpi=200)

# Save as PDF
ggsave("results/representation_photos.pdf", gp, w=6.5, h=3.1)
