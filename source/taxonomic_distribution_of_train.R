#!/usr/bin/env Rscript
library(tidyverse)

# Define infiles
taxonomy_file = "results/train.filtered.taxonomy.tab"
levenshtein_file = "intermediate/train.standard_aa.LD.tab"
colours_file = "data/colours.txt"

# Load data
taxonomy = read_tsv(taxonomy_file)
levenshtein = read_tsv(levenshtein_file, col_names=c("SeqA", "SeqB", "LD"))
colours = scan(colours_file, character())

# Add Levenshtein distance to taxonomy
taxonomy = levenshtein %>%
  mutate(identifier = ifelse(SeqA == "sp|P73922|FBSB_SYNY3", SeqB, SeqA)) %>%
  select(identifier, LD) %>%
  inner_join(taxonomy)

taxonomy = taxonomy %>%
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
  summarise(Count = length(group), Distance = mean(LD)) %>%
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
default_colour = "#d9d9d9"
colour_summary = taxonomy %>%
  mutate(
    Colour = case_when(
      group == "Cyanobacteria" ~ "#a6dba0",
      group == "Other" ~ default_colour,
      group == "Viridiplantae" ~ "#5aae61",
      superkingdom == "Bacteria" ~ "#c2a5cf",
      superkingdom == "Archaea" ~ "#9970ab",
      superkingdom == "Eukaryota" ~ "#dfc27d",
      T ~ default_colour
    )
  ) %>%
  group_by(Organism) %>%
  summarise(
    Count = length(group), Distance = mean(LD), Colour = unique(Colour)
  ) %>%
  arrange(-Count) %>%
  # mutate(Colour = colours) %>%
  # # Change colour for Cyanobacteria
  # mutate(
  #   Colour = ifelse(
  #     Colour == "#5aae61",
  #     filter(., Organism == "Cyanobacteria")$Colour,
  #     Colour
  #   ),
  #   Colour = ifelse(Organism == "Cyanobacteria", "#5aae61", Colour)
  # ) %>%
  # Arrange according to Distance
  arrange(-Distance)

# Organize Organism according to mean distance
taxonomy = taxonomy %>%
  mutate(Organism = factor(Organism, levels = colour_summary$Organism))

# Plot taxonomic distribution
gp = ggplot(taxonomy, aes(x=Organism, fill=Organism))
gp = gp + geom_bar()
gp = gp + theme_bw()
gp = gp + theme(
  axis.ticks = element_line(colour="black"),
  axis.text = element_text(colour="black", size=6),
  axis.title = element_text(size=8)
)
gp = gp + coord_flip()
gp = gp + ylab("Number of sequences")
gp = gp + scale_fill_manual(values=colour_summary$Colour, guide=F)

gp1 = gp

# Plot Distance distributions
gp = ggplot(taxonomy, aes(x=Organism, y=LD))
gp = gp + geom_boxplot(outlier.size=0.5)
gp = gp + theme_bw()
gp = gp + theme(
  axis.ticks = element_line(colour="black"),
  axis.text = element_text(colour="black", size=6),
  axis.text.y = element_blank(),
  axis.title.y = element_blank(),
  axis.ticks.y = element_blank(),
  axis.title = element_text(size=8)
)
gp = gp + coord_flip()
gp = gp + ylab("Levenshtein distance to Synechocystis FBPase")

gp2 = gp

# Arrange plot
library(egg)

outfile = "data/taxonomic_distribution_of_train.png"

png(outfile, width=180/25.4, height=80/25.4, res=200, units="in")
ggarrange(gp1, gp2, ncol=2)
garbage = dev.off()
