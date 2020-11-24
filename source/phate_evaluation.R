#!/usr/bin/env Rscript
library(tidyverse)
library(phateR)
options(width=150)

# Define infiles
colour_file = "data/colours.txt"
taxonomy_file = "results/train.filtered.taxonomy.tab"
seqidseq_file = "intermediate/train.seqid_seq.tab"
unireps_file = "intermediate/validation_reps.unirep.tab.gz"
evoreps_file = "intermediate/validation_reps.evotuned.tab.gz"
valseqs_file = "results/evotuned/fbpase/validation_sequences.txt"

# Load data
colours = scan(colour_file, character())
taxonomy = read_tsv(taxonomy_file)
seqidseq = read_tsv(seqidseq_file, col_names=c("identifier", "Sequence"))
unireps = read_tsv(unireps_file, col_names=F)
evoreps = read_tsv(evoreps_file, col_names=F)
valseqs = scan(valseqs_file, character())

# Get validation sequences in correct order
seqidseq = seqidseq %>%
  right_join(tibble(Sequence=valseqs, Order=1:length(valseqs))) %>%
  arrange(Order)

# Make representation matrices with identifiers as rownames
uniX = as.matrix(unireps)
evoX = as.matrix(evoreps)
rownames(uniX) = seqidseq$identifier
rownames(evoX) = seqidseq$identifier

# Perform PHATE
uni_phate = phate(uniX)
evo_phate = phate(evoX)

# Prepare data for plotting
plot_phate = bind_rows(
  uni_phate$embedding %>%
    as.tibble() %>%
    mutate(
      identifier = seqidseq$identifier,
      Parameters = "UniRep"
    ),
  evo_phate$embedding %>%
    as.tibble() %>%
    mutate(
      identifier = seqidseq$identifier,
      Parameters = "Evotuned"
    )
  )

# Prepare taxonomy data for plotting
taxonomy = taxonomy %>%
  filter(identifier %in% seqidseq$identifier) %>%
  mutate(
    # For eukaryotes, select Kingdom as the Group
    group = ifelse(superkingdom == "Eukaryota", kingdom, group),
    # Count organisms without superkingdom as "Other"
    group = ifelse(
      is.na(group),
      str_trim(paste("Other", replace_na(superkingdom, ""))),
      group
    )
  )

# Count group members, select top 15 non-Other groups
top_groups = taxonomy %>%
  filter(!startsWith(group, "Other")) %>%
  group_by(group) %>%
  summarise(Count = length(group)) %>%
  arrange(-Count) %>%
  slice_head(n=15)

# Create the Organism classification
taxonomy = taxonomy %>%
  mutate(
    Organism = ifelse(
      # If group is among top, Organism is group
      group %in% top_groups$group, group,
      # Otherwise it is Other Archaea, Other Bacteria, Other Eukaryota, or Other
      str_trim(paste("Other", replace_na(superkingdom, "")))
    ),
    # Fix for viruses
    Organism = ifelse(Organism == "Other Viruses", "Other", Organism)
  )

# Summarise data and add colours
colour_summary = taxonomy %>%
  group_by(Organism) %>%
  summarise(Count = length(Organism)) %>%
  arrange(-Count) %>%
  mutate(Colour = colours) %>%
  # Change colour for Cyanobacteria
  mutate(
    Colour = ifelse(
      Colour == "#5aae61",
      filter(., Organism == "Cyanobacteria")$Colour,
      Colour
    ),
    Colour = ifelse(Organism == "Cyanobacteria", "#5aae61", Colour)
  )

# Add colour to plotting data
plot_phate = plot_phate %>%
  inner_join(select(taxonomy, identifier, Organism)) %>%
  mutate(Organism = factor(Organism, levels = colour_summary$Organism))

# Plot
gp = ggplot(plot_phate, aes(x=PHATE1, y=PHATE2, colour=Organism))
gp = gp + geom_point(alpha=0.5, stroke=0, size=1.2)
gp = gp + scale_color_manual(values=colour_summary$Colour)
gp = gp + facet_grid(~Parameters)
gp = gp + theme_bw()
gp = gp + theme(
  aspect.ratio=1,
  axis.text=element_text(colour="black"),
  axis.ticks=element_line(colour="black"),
  strip.background=element_blank(),
  legend.position="bottom",
  legend.text=element_text(size=7),
  legend.title=element_blank(),
  legend.background=element_blank()
)
gp = gp + guides(colour=guide_legend(nrow=5, keyheight=0.8))
gp = gp + ggtitle(
  paste(
    "Distribution of",
    length(valseqs),
    "validation sequences using different parameters"
  )
)

ggsave("data/phate_evaluation.png", gp, w=6.5, h=4.9, dpi=200)
