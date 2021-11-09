#!/usr/bin/env Rscript
library(tidyverse)
library(phateR)
options(width=110)

# Define infiles
colour_file = "data/colours.txt"
fbpase_taxonomy_file = "results/FBPase/taxonomy/train.filtered.taxonomy.tab"
rubisco_taxonomy_file = "results/Rubisco/taxonomy/train.filtered.taxonomy.tab"
seqidseq_file = "intermediate/train.enzyme_seqid_seq.tab"
reps_file = "intermediate/validation_reps.fbpase_rubisco.tab.gz"

# Load data
colours = scan(colour_file, character())
taxonomy = bind_rows(
  read_tsv(fbpase_taxonomy_file),
  read_tsv(rubisco_taxonomy_file)
)
seqidseq = read_tsv(
  seqidseq_file, col_names=c("Enzyme", "identifier", "Sequence")
)
reps = seqidseq %>%
  inner_join(
    read_tsv(reps_file, col_names=F) %>%
      rename(Parameters = X1, Sequence = X2)
  )

# Make representation matrices with identifiers as rownames
do_phate = function(r){
  # Make matrix
  rX = as.matrix(select(r, -Enzyme, -identifier, -Sequence, -Parameters))
  # Add identifier as rownames
  rownames(rX) = r$identifier
  # Perform PHATE
  r_phate = phate(rX)
  # Format output
  r_phate$embedding %>%
    as_tibble() %>%
    mutate(
      Enzyme = r$Enzyme,
      Parameters = r$Parameters,
      identifier = r$identifier
    )
}

# Perform PHATE
plot_phate = bind_rows(
  reps %>%
    group_by(Enzyme, Parameters) %>%
    group_split() %>%
    lapply(do_phate)
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
gp = gp + facet_grid(Enzyme~Parameters)
gp = gp + theme_bw()
gp = gp + theme(
  aspect.ratio=1,
  axis.text=element_text(colour="black"),
  axis.ticks=element_line(colour="black"),
  strip.background=element_blank(),
  legend.position="bottom",
  legend.text=element_text(size=10),
  legend.title=element_blank(),
  legend.background=element_blank()
)
gp = gp + guides(colour=guide_legend(nrow=5, keyheight=0.8))

ggsave("results/phate_fbpase_rubisco.png", gp, w=9, h=7, dpi=200)
