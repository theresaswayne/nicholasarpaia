# testing interaction counts

require(tidyverse) # for data processing
require(stringr) # for string harvesting
require(RcppRoll) # for scanning interactions

# create test data
t <- c(1,1,2,2,3,3,4)
objA <- c(1,3,1,2,2,3,2)

# sorted by t
testdata <- data.frame("t" = t, "objA" = objA)

# sorted by obj number
sorted <- testdata %>% 
  arrange(objA)

# suggestion from StackOverflow -- works to count but it's not rolling; 
# only checks from the first interaction

count_freq <- function(timestamps){                                             
  #Given all the ocurrences of interactions with an object find the 
  #earliest one and count how many occur within 24 hours
  timeWindow <- 2
  dtime <- sort(timestamps)                                            
  start_time <- dtime[1]                                           
  end_time <- start_time + timeWindow                                            
  sum(dtime >= start_time & dtime <= end_time)  # counts the occurrences between the earliest and latest in that window                                
}

out <- group_by(testdata, objA) %>% 
  summarise(freq = count_freq(t)) 

# create a logical vector containing the interacting timepoints for a single object
timepoints <- min(t):max(t)
objA1int <- testdata %>% 
  filter(objA == 1) # rows of the dataset where obj A1 is interactings

objA1times <- timepoints %in% objA1int$t # all timepoints, TRUE where A1 is interacting, FALSE where not

# now we need a function or loop to apply this across all objA's 
# see https://stackoverflow.com/questions/55921893/check-for-a-match-between-a-list-of-values-and-a-column-entry-in-r

objA_IDs <- sort(unique(testdata$objA))


# set it up as a for loop (could probably be converted to lapply, se)
# https://www.r-bloggers.com/2019/01/parallelize-a-for-loop-by-rewriting-it-as-an-lapply-call/
  
# see https://stackoverflow.com/questions/55921893/check-for-a-match-between-a-list-of-values-and-a-column-entry-in-r


output <- data.frame("t" = timepoints) # this serves as the 1st col

for (obj in objA_IDs) {
  objInts <- testdata %>% 
    filter(objA == obj)
  objTimes <- timepoints %in% objInts$t
  objName <- as.character(obj)
  output[[paste0("",obj)]] <- objTimes
}


