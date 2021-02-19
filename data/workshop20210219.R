#R script for the Duke Data Journalism Lab
#workshop on Feb. 19, 2021

# Getting started ---------------------------------------------------------

#set working directory to the data folder of the downloaded repository
setwd("~/Dropbox/projects/duke/data_lab/spring_2020/data-journalism-with-r/data/")

#install the tidyverse package
install.packages("tidyverse")
install.packages("knitr")
install.packages("stringr")
install.packages("janitor")

#load our packages from our library into our workspace
library(tidyverse)
library(knitr)
library(stringr)
library(janitor)

#load in our data downloaded from 
ppp1 <- read_csv('../originals/public_150k_plus.csv')
ppp2 <- read_csv('../originals/public_up_to_150k_1.csv')
ppp3 <- read_csv('../originals/public_up_to_150k_2.csv')
ppp4 <- read_csv('../originals/public_up_to_150k_3.csv')
ppp5 <- read_csv('../originals/public_up_to_150k_4.csv')
ppp6 <- read_csv('../originals/public_up_to_150k_5.csv', guess_max = 2000)
ppp7 <- read_csv('../originals/public_up_to_150k_6.csv')

#combine it all
ppp <- rbind(ppp1, ppp2, ppp3, ppp4, ppp5, ppp6, ppp7)

#filter for NC and output to a csv file
ppp %>% 
  filter(BorrowerState == 'NC') %>%
  write.csv('ppp_nc20210201.csv', row.names = FALSE)

#load in our fresh data
ppp <- read_csv('ppp_nc20210201.csv')

#load in our naics code lookups
naics <- read_csv('naics_lookup.csv')

# Basic gut checks --------------------------------------------------------

#how many rows do we have?
ppp %>% 
  nrow()

#are we only looking at NC?
ppp %>% 
  count(BorrowerState)

ppp %>% 
  count(ProjectState)

#what's our total loan value?
ppp %>% 
  summarize(total = sum(InitialApprovalAmount))

#what about the average?
ppp %>% 
  summarize(avg = mean(InitialApprovalAmount))

#what's the median?
ppp %>% 
  summarize(total = median(InitialApprovalAmount))

#disable scientific notation
options(scipen=999)

#who got the largest loan?
ppp %>% 
  arrange(desc(InitialApprovalAmount)) %>%
  select(BorrowerName, BorrowerCity, InitialApprovalAmount) %>% 
  head() %>% 
  kable('simple')

#who got the smallest loan?
ppp %>% 
  arrange(InitialApprovalAmount) %>%
  select(BorrowerName, BorrowerCity, InitialApprovalAmount) %>% 
  head() %>% 
  kable('simple')

#give me a rundown of the column names
ppp %>% 
  names()

# Cleaning and grouping ---------------------------------------------------
#group by county
ppp %>% 
  count(ProjectCountyName, name = 'loan_count') %>% 
  arrange(desc(loan_count)) %>% 
  kable('simple')

#group by city
ppp %>% 
  count(ProjectCity, name = 'loan_count') %>% 
  arrange(desc(loan_count)) %>% 
  kable('simple')

#clean up the city name just by normalizing the capitalization
ppp <- ppp %>% 
  mutate(ProjectCity_clean = toupper(ProjectCity)) %>% 
  mutate(ProjectCity_clean = str_remove_all(ProjectCity_clean, '\\.')) %>% 
  relocate(ProjectCity_clean, .after = ProjectCity)

#and regroup by city on the clean column
ppp %>% 
  count(ProjectCity_clean, name = 'loan_count') %>% 
  arrange(desc(loan_count)) %>% 
  kable('simple')


# Joining data ------------------------------------------------------------

ppp <- ppp %>%
  mutate(naics_initial_code = strtoi(substr(NAICSCode, start = 1, stop = 2))) %>% 
  relocate(naics_initial_code, .after = NAICSCode)

ppp %>%
  left_join(naics, by = c('naics_initial_code')) %>% 
  group_by(naics_title) %>% 
  summarize(total = sum(InitialApprovalAmount)) %>% 
  arrange(desc(total)) %>% 
  adorn_totals() %>% 
  adorn_percentages('col') %>% 
  adorn_pct_formatting() %>%
  adorn_ns(position = "front") %>% 
  kable('simple')
