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


# ---- Get the data ----
# no message will be displayed. Choose the file to analyze
selectedFile <- file.choose()
inputFolder <- dirname(selectedFile) # the input is the parent of the selected file

data <- read_csv(selectedFile)

# ---- Reformat the data ---

# remove unneeded columns
data <- data %>% 
  select(filename, Label, timepoint) # all rows

# split Label to identify object names
# format: objA1_objB7
data <- data %>%
  separate_wider_delim("Label", delim="_", names=c("ObjA", "ObjB"))

# get the Object A numbers by capturing what's after "objA"
Anums <- str_replace(data$ObjA, "objA(.*)", "\\1")

# get the Object B numbers by capturing what's after "objB"
Bnums <- str_replace(data$ObjB, "objB(.*)", "\\1")

# substitute the cleaned data for the original
data <- data %>% mutate(ObjA = Anums,
                                  ObjB = Bnums)

# ---- Count interactions ----

# total interactions per timepoint
intPerTime <- data %>% 
  count(timepoint)

# total interactions per T cell (objA)
intPerA <- data %>%
  count(ObjA)



