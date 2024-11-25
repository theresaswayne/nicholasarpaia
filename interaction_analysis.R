# R script to extract interaction data from ImageJ DiAnA plugin output

# Assumptions:
# CSV data from multiple timepoints are merged 
# Cols: filename, Label, timepoint and other data (not needed)
# Label column data is of the format objA1_objB7 
# Outputs:
# number of objects in the A class that show interactions
# number of objects in the A class that show persistent interactions 

# ---- Setup ----

require(tidyverse) # for data processing
require(stringr) # for string harvesting
require(RcppRoll) # for scanning interactions
require(xfun) # for filename manipulation

# ---- Parameters ----
# change these as needed 

# object A represents a Treg and object B represents a fibroblast
objAname = "Treg"
objBname = "Fibroblast"

# time window size (units = timepoints) for checking persistence of interactions
# threshold is the number of interactions within that window to be considered consistent
# if time window == threshold, then you must have that many consecutive interactions
# if time window > threshold, then the interactions may be non-consecutive but must occur within the window

timeWindow <- 22
threshold <- 8

# ---- Get the data ----
# no message will be displayed. Choose the file to analyze
selectedFile <- file.choose()
parentFolder <- dirname(selectedFile) # parent of the selected file

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


# function to return TRUE if any rolling sums in the window = window size (consecutive contacts)
intxnsWithoutT <- intxns[,-1] # omit the t column
persist <- intxnsWithoutT %>%
  summarise_all(function(x) {
    ifelse(max(roll_sum(x, n = timeWindow, weights = NULL, fill = numeric(0),
                        partial = FALSE, align = "left", normalize = TRUE,
                        na.rm = FALSE)) >= threshold, TRUE, FALSE)
  })

# pivot the table to get the number and % persistent
persistSummary <- persist %>% 
  pivot_longer(cols = everything(), names_to = "ObjA", values_to = "Persistent")

totalIntxns <- nrow(persistSummary)
totalPersistent <- sum(persistSummary$Persistent == TRUE)
fracPersistent <- totalPersistent/totalIntxns

# TODO: Add threshold to table
resultHeaders <- c("Filename", "Window", "Threshold", "Total Interacting",  "Persistent Interacting","Fraction Persistent")
resultValues <- c(basename(selectedFile), timeWindow, threshold, totalIntxns, totalPersistent, fracPersistent)
resultTable <- data.frame(rbind(resultHeaders, resultValues))
names(resultTable) <- resultTable[1,]
resultTable <- resultTable[-1,]

# create output

# intxns (may be able to use for survival analysis)
intxnFile = paste(sans_ext(basename(selectedFile)), "_interactions.csv", sep = "")
write_csv(intxns,file.path(parentFolder, intxnFile))

# persistSummary (derived data)
persistFile = paste(sans_ext(basename(selectedFile)), "_persistence.csv", sep = "")
write_csv(persistSummary,file.path(parentFolder, persistFile))

# summary (final calculations)
resultFile = paste(sans_ext(basename(selectedFile)), "_summary.csv", sep = "")
write_csv(resultTable,file.path(parentFolder, resultFile))

# TODO: Survival curves