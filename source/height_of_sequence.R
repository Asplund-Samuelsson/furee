#!/usr/bin/env Rscript

tree_file = "intermediate/height_estimation/3.tree"
reftree_file = "data/FireProt_Syn6803_ASR.tree"
target = "target"
ref_query = "query"
query = "sp|P73922|FBSB_SYNY3"

# Read arguments from commandline
args = commandArgs(trailingOnly=T)
tree_file = args[1] # A tree file
reftree_file = args[2] # Reference tree to determine rooting from
target = args[3] # The tip to determine height of
ref_query = args[4] # Reference query to determine height of in reference tree
query = args[5] # Reference query to determine height of in current tree
outfile = args[6] # A height value

options(width=150)
library(tidyverse)
library(phytools)

# Load data
the_tree = read.tree(tree_file)
reftree = read.tree(reftree_file)

# Clean up tiplabels
the_tree$tip.label = str_replace_all(the_tree$tip.label, "\"", "")
reftree$tip.label = str_replace_all(reftree$tip.label, "\"", "")

# Function to get left and right tips of split at root
get_tip_split = function (a_tree) {
  # Edges are parent-child relations
  relations = a_tree$edge %>% as_tibble() %>% rename(Parent = V1, Child = V2)

  # Get the two child nodes of the reference root
  root_children = filter(relations, Parent == relations[1,1]$Parent)$Child

  # Get the descendants of each root node child
  l_clade = getDescendants(a_tree, root_children[1])
  r_clade = getDescendants(a_tree, root_children[2])

  # Get the tip labels of each root node child
  l_tips = a_tree$tip.label[l_clade[which(l_clade < relations[1,1]$Parent)]]
  r_tips = a_tree$tip.label[r_clade[which(r_clade < relations[1,1]$Parent)]]

  # Return split tips
  return(list(left=l_tips, right=r_tips))
}

# Get the reference tips for a split at the root
ref_split = get_tip_split(reftree)

# Go through every possible split of the tree and record overlap with reference
# root split clades
root_overlaps = bind_rows(lapply(
  unique(the_tree$edge[,1]),
  function (n) {
    # Split on each possible root
    root_split = get_tip_split(root(the_tree, node=n))
    # Determine overlap with reference split
    ll = length(intersect(root_split$left, ref_split$left))
    lr = length(intersect(root_split$left, ref_split$right))
    rl = length(intersect(root_split$right, ref_split$left))
    rr = length(intersect(root_split$right, ref_split$right))
    # Count overlaps for each possible combination of matching splits
    a = ll + rr
    b = lr + rl
    # Save the maximal overlap
    tibble(Node = n, Overlap = max(c(a, b)))
  }
)) %>% arrange(-Overlap)

# Get the node of the best overlap in order to root tree correctly
root_node = root_overlaps$Node[1]

# Reroot the query tree and identify height of target
rooted_tree = root(the_tree, node=root_node)

heights = tibble(
  Node = rooted_tree$edge[,2],
  Height = nodeHeights(rooted_tree)[,2]
) %>% mutate(Tiplabel = rooted_tree$tip.label[Node])

heights_ref = tibble(
  Node = reftree$edge[,2],
  Height = nodeHeights(reftree)[,2]
) %>% mutate(Tiplabel = reftree$tip.label[Node])

target_height = filter(heights, Tiplabel == target)$Height
ref_query_height = filter(heights_ref, Tiplabel == ref_query)$Height
query_height = filter(heights, Tiplabel == query)$Height
max_height = max(heights$Height)
max_ref_height = max(heights_ref$Height)

# Save data
write_tsv(
  tibble(
    Target = target, Query = query, Reference = ref_query,
    Target_height = target_height,
    Query_height = query_height,
    Reference_height = ref_query_height,
    Max_height = max_height,
    Max_reference_height = max_ref_height
  ),
  outfile
)
