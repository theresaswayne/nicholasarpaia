# R script to extract interaction data from ImageJ DiAnA plugin output

# Assumptions:
# CSV data from multiple timepoints are merged 
# Cols: filename, Label, timepoint and other data (not needed)
# Label column data is of the format objA1_objB7 
# Outputs number of interactions per object in the A class and consecutive interactions in a given window size

# ---- Setup ----

require(tidyverse) # for data processing
require(stringr) # for string harvesting
require(RcppRoll) # for scanning interactions

# ---- Parameters ----
# change these as needed 

# object A represents a Treg and object B represents a fibroblast
objAname = "Treg"
objBname = "Fibroblast"

# time window size for checking persistence of interactions
timeWindow <- 2

# ---- Get the data ----
# no message will be displayed. Choose the file to analyze
selectedFile <- file.choose()
inputFolder <- dirname(selectedFile) # the input is the parent of the selected file

df <- read_csv(selectedFile)

# ---- Reformat the data ---

# remove unneeded columns
df <- df %>% 
  select(filename, Label, timepoint) # all rows

# split Label to identify object names
# format: objA1_objB7
df <- df %>%
  separate_wider_delim("Label", delim="_", names=c("ObjA", "ObjB"))

# get the Object A numbers by capturing what's after "objA"
Anums <- str_replace(df$ObjA, "objA(.*)", "\\1")

# get the Object B numbers by capturing what's after "objB"
Bnums <- str_replace(df$ObjB, "objB(.*)", "\\1")

# substitute the cleaned data for the original
df <- df %>% mutate(ObjA = Anums,
                                  ObjB = Bnums)

# ---- Count interactions ----

# total interactions per timepoint
intPerTime <- df %>% 
  count(timepoint)

# total interactions per T cell (objA)
intPerA <- df %>%
  count(ObjA) %>% 
  arrange(as.integer(ObjA))

# table of interactions across time

timepoints <- min(df$timepoint):max(df$timepoint) # unique row for each timepoint

objA_IDs <- sort(as.integer(unique(df$ObjA))) # all the interacting objects across the dataset

# create a logical vector for each obj containing the interacting timepoints for a single object

intxns <- data.frame("t" = timepoints) # this serves as the 1st col

for (obj in objA_IDs) {
  objInts <- df %>% 
    filter(ObjA == obj)
  objTimes <- timepoints %in% objInts$timepoint
  intxns[[paste0("",obj)]] <- objTimes # add a column with interactions for that object
}

# calculate a rolling sum along the logical vector

# check the total calculation (compare to intPerA above)
intPerALogical <- intxns[,-1]  #omit the t column
intPerALogical <- intPerALogical %>% 
  pivot_longer(cols = everything(), names_to = "ObjA", values_to = "val") %>%
  group_by(ObjA) %>%
  summarise(Total = sum(val)) %>% 
  arrange(as.integer(ObjA))


# single column example
# output is a vector giving the sums at each successive window

A1roll <- roll_sum(intxns$'1', n = timeWindow, weights = NULL, fill = numeric(0),
                   partial = FALSE, align = "left", normalize = TRUE,
                   na.rm = FALSE)

# TODO: Loop going across all ObjIDs
# TODO: Ifelse or other statement recording TRUE if A1roll > 0
# TODO: create output vector showing true or false for persistent interaction per ObjID
# TODO: Calculate number of persistent interactions and % of total
# TODO: Survival curves