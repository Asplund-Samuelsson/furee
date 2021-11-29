options(width=110)
library(tidyverse)
library(foreach)
library(doMC)

# Define infiles
inpath = "results/diff_vs_ratio"

# List infiles
infiles = tibble(
  File = list.files(inpath),
  Path = list.files(inpath, full.names=T)
) %>%
  mutate(
    Replicate = str_remove(File, ".tab$") %>% str_split("_") %>% sapply("[",1),
    Temperature = str_remove(File, ".tab$") %>% str_split("_") %>% sapply("[",2),
    Comparison = str_remove(File, ".tab$") %>% str_split("_") %>% sapply("[",3)
  )

# Load all data
registerDoMC(20)
df = bind_rows(
  foreach(i=1:nrow(infiles)) %dopar% {
    infile = infiles[i,]
    read_tsv(infile$Path) %>%
      mutate(
        Replicate = infile$Replicate,
        Temperature = infile$Temperature,
        Comparison = infile$Comparison
      )
  }
)

# Fold into rows
df = df %>%
  select(-sequences) %>%
  gather(Data, Value, -accept, -step, -Replicate, -Temperature, -Comparison) %>%
  # Use only accepted data
  filter(accept)

# For each step, calculate mean value
df_mean = bind_rows(lapply(
  0:200,
  function(s){
    df %>%
      filter(step <= s) %>%
      group_by(Replicate, Temperature, Comparison, Data) %>%
      top_n(1, step) %>%
      group_by(Temperature, Comparison, Data) %>%
      summarise(Value=mean(Value), .groups="keep") %>%
      mutate(step = s) %>%
      ungroup()
  }
))

# Combine data
df_plot = bind_rows(
  df %>% select(-accept) %>% mutate(Type = "Replicate"),
  df_mean %>% mutate(Replicate = "0", Type = "Mean")
) %>%
  # Add grouping variable
  mutate(Group = paste(Replicate, Type, Comparison)) %>%
  # Add T to temperature
  mutate(
    Temperature = factor(
      paste("T =", Temperature),
      levels=paste(
        "T =",
        arrange(., as.numeric(Temperature)) %>%
          pull(Temperature) %>%
          unique()
      )
    )
  )

# Plot it
gp = ggplot(
  df_plot,
  aes(
    group=Group,
    alpha=Type,
    x=step, y=Value, colour=Comparison
  )
)
gp = gp + geom_line()
gp = gp + facet_grid(Data~Temperature, scales="free_y", switch="y")
gp = gp + scale_colour_manual(values=c("#b0636f", "#2b5168"))
gp = gp + scale_alpha_manual(values=c(1,0.2))
gp = gp + theme_bw()
gp = gp + theme(
  axis.ticks=element_line(colour="black"),
  axis.text=element_text(colour="black"),
  strip.background=element_blank(),
  legend.position="top",
  axis.title.y=element_blank(),
  strip.placement = "outside"
)

ggsave("results/diff_vs_ratio.png", gp, h=12/2.54, w=20/2.54, dpi=200)
