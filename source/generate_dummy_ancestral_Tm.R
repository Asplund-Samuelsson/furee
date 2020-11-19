options(width=100)
library(tidyverse)
library(phytools)
library(ggtree)

# Define infiles
asr_tree_file = "data/FireProt_Syn6803_ASR.tree"

# Load data
asr_tree = read.tree(asr_tree_file)

# Edges are parent-child relations
relations = bind_cols(
  # Extract node pairs of edges
  asr_tree$edge %>% as_tibble() %>% rename(Parent = V1, Child = V2),
  # Extract node heights
  nodeHeights(asr_tree) %>% as_tibble() %>% rename(Parent_h = V1, Child_h = V2)
)

# Height zero should tend to Tm 80, while max height should tend to Tm 55
# Determine the rate of change in Tm per height
Tm_evolution_rate = (80 - 55) / max(relations$Child_h)

# Set Tm to NA to begin with
relations$Tm = NA

# Recursive function to evolve Tm
evolve_Tm = function(n, relations) {
  # Determine parent Tm
  parent_Tm = filter(relations, Child == n)$Tm
  # If there is no parent Tm, it is the root
  if (length(parent_Tm) == 0) {parent_Tm = 80}
  # Sample a Tm for each child based on difference to parent and tendency
  relations = relations %>%
    mutate(
      Tm = ifelse(
        Parent == n,
        parent_Tm - unlist(lapply(
          Child_h - Parent_h,
          function (x) {
            rnorm(1, x*Tm_evolution_rate, max(1, x*Tm_evolution_rate))
          }
        )),
        Tm
      )
    )
  # Evolve the children
  for (child in filter(relations, Parent == n)$Child) {
    relations = evolve_Tm(child, relations)
  }
  # Return relations
  return(relations)
}

# Evolve the Tm
relations = evolve_Tm(asr_tree$edge[1,1], relations)

# Plot the results on a tree
gp = ggtree(asr_tree, aes(colour=Tm), layout="rectangular")
gp$data = gp$data %>%
  left_join(
    relations %>%
      select(Parent, Child, Tm) %>%
      rename(parent = Parent, node = Child)
  ) %>%
  mutate(Tm = ifelse(node == asr_tree$edge[1,1], 80, Tm))
gp = gp + geom_nodepoint(mapping=aes(fill=Tm), shape=21)
gp = gp + geom_tippoint(mapping=aes(fill=Tm), shape=24)
gp = gp + scale_colour_viridis_c(option="B")
gp = gp + scale_fill_viridis_c(option="B")
gp = gp + geom_treescale(x=0, y=0, fontsize=3)
gp = gp + geom_tiplab(align=T)
gp = gp + xlim(0, max(relations$Child_h)*1.5) # Fix cut off tiplabs

ggsave(
  "data/dummy_ancestral_Tm_on_tree.pdf",
  gp, width=30, height=24, units="cm"
)

# Save final Tm values
Tm_values = relations %>%
  select(Child, Tm) %>%
  bind_rows(tibble(Child = asr_tree$edge[1,1], Tm=80)) %>%
  mutate(
    Sequence_ID = str_replace_all(asr_tree$tip.label, "\"", "")[Child],
    Sequence_ID = ifelse(
      is.na(Sequence_ID),
      paste("ancestral", Child, sep="_"),
      Sequence_ID
    )
  ) %>%
  select(-Child)

write_tsv(Tm_values, "data/dummy_ancestral_Tm.tab")
