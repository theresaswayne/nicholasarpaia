# extract interaction data from DiAnA output

# Assumptions:
# CSV data from each timepoint is merged with filenames in order corresponding to timepoint
# Cols: filename, Label, timepoint and other data (not needed)
# Label column data is of the format objA1_objB7 
# Outputs number of interactions per object in the A class and consecutive interactions in a given window size


# ---- Setup ----

require(tidyverse) # for data processing
require(stringr) # for string harvesting

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

rawdata <- read_csv(selectedFile)

# ---- Reformat the data ---

# remove unneeded columns
data <- rawdata %>% 
  select(filename, Label, timepoint) # all rows

# split Label to identify object names
# format: objA1_objB7
datasplit <- data %>%
  separate_wider_delim("Label", delim="_", names=c("ObjA", "ObjB"))

# Get the Object A numbers

# collect ROI names -- for new style ROI names (Area(ROI_1)_sum)
#Area_rois <- str_replace(Area_cols, "Area\\((.*)\\)_sum", "\\1")
#numArea_rois <- str_replace(numArea_cols, "Area\\((.*)\\)_sum", "\\1")
#denomArea_rois <- str_replace(denomArea_cols, "Area\\((.*)\\)_sum", "\\1")

