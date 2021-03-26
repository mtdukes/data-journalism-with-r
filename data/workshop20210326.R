#R script for the Duke Data Journalism Lab
#workshop on March 26, 2021

#set working directory to the data folder of the downloaded repository
#setwd('~/Dropbox/projects/duke/data_lab/spring_2020/data-journalism-with-r/data/')
setwd("~/Desktop/data-journalism-with-r/data")

#install other packages
install.packages('zoo')
install.packages('geofacet')

#load the libraries we'll be using
library(tidyverse)
library(knitr)
library(zoo)
library(geofacet)
library(stringr)

#load in our fresh data
covid_time_series <- read_csv('jhu_covid.csv')

# Gut checks --------------------------------------------------------------

#count the total number of rows
covid_time_series %>% 
  nrow()

#count the rows in the NC data
covid_time_series %>%
  filter(Province_State == 'North Carolina') %>% 
  nrow()

#examine the county list for the NC data
#and put it in a nice table
covid_time_series %>%
  filter(Province_State == 'North Carolina') %>% 
  select(Admin2) %>% 
  kable('simple')

#count up the total number of cases for the last date
covid_time_series %>%
  filter(Province_State == 'North Carolina') %>% 
  summarize(across('3/25/21',sum))

# Simple line chart -------------------------------------------------------

#create a durham only dataset and drop our unneeded columns
durham_covid <- covid_time_series %>%
  filter(Province_State == 'North Carolina' & Admin2 == 'Durham') %>% 
  select(-UID, -iso2, -iso3, -code3, -Country_Region, -Lat, -Long_, -Combined_Key)

#reformat our data from wide to long
#by telling our function what columns we don't want split
#and clean up our date column
durham_covid <- durham_covid %>% 
  pivot_longer(!c(FIPS,Admin2,Province_State), names_to = 'date', values_to = 'case_count') %>% 
  mutate(date = as.Date(date, format="%m/%d/%y"))

#plot the case count over time
durham_covid %>% 
  ggplot(aes(date, case_count))+
  geom_line()

#clean up and style
durham_covid %>%
  filter(date > '2020-03-01') %>% 
  ggplot(aes(date, case_count))+
  geom_line(color = '#2b8cbe') +
  scale_x_date(date_breaks = '2 months', date_labels = "%b %y") +
  labs(title = "Durham COVID-19 case counts over time",
       caption = "SOURCE: Johns Hopkins University",
       x = "",
       y = "Case count") +
  theme(strip.text.x = element_text(size = 10),
        strip.background.x = element_blank(),
        axis.line.x = element_line(color="black", size = 0.25),
        axis.line.y = element_line(color="black", size = 0.25),
        panel.grid.major.x = element_line( color="grey", size = 0.25 ) ,
        panel.grid.major.y = element_line( color="grey", size = 0.25 ) , 
        axis.ticks = element_blank(),
        panel.background = element_blank(),
        plot.title = element_text(size = 12),
  )

#calculate new cases as a new column
durham_covid <- durham_covid %>%
  mutate(new_cases = case_count - lag(case_count,1))

#chart new cases instead of cases overall
durham_covid %>%
  filter(date > '2020-03-01') %>% 
  ggplot(aes(date, new_cases))+
  geom_line(color = '#2b8cbe') +
  scale_x_date(date_breaks = '2 months', date_labels = "%b %y") +
  labs(title = "Durham COVID-19 case counts over time",
       caption = "SOURCE: Johns Hopkins University",
       x = "",
       y = "Case count") +
  theme(strip.text.x = element_text(size = 10),
        strip.background.x = element_blank(),
        axis.line.x = element_line(color="black", size = 0.25),
        axis.line.y = element_line(color="black", size = 0.25),
        panel.grid.major.x = element_line( color="grey", size = 0.25 ) ,
        panel.grid.major.y = element_line( color="grey", size = 0.25 ) , 
        axis.ticks = element_blank(),
        panel.background = element_blank(),
        plot.title = element_text(size = 12),
  )

#calculate rolling average of new cases as a new column
durham_covid <- durham_covid %>%
  mutate(rolling_new = round(rollmean(new_cases, 7, na.pad = TRUE, align="right")))

#chart the rolling average of cases instead of cases overall
durham_covid %>%
  filter(date > '2020-03-01') %>% 
  ggplot(aes(date, rolling_new))+
  geom_line(color = '#2b8cbe') +
  scale_x_date(date_breaks = '2 months', date_labels = "%b %y") +
  labs(title = "Durham COVID-19 case counts over time",
       caption = "SOURCE: Johns Hopkins University",
       x = "",
       y = "Case count") +
  theme(strip.text.x = element_text(size = 10),
        strip.background.x = element_blank(),
        axis.line.x = element_line(color="black", size = 0.25),
        axis.line.y = element_line(color="black", size = 0.25),
        panel.grid.major.x = element_line( color="grey", size = 0.25 ) ,
        panel.grid.major.y = element_line( color="grey", size = 0.25 ) , 
        axis.ticks = element_blank(),
        panel.background = element_blank(),
        plot.title = element_text(size = 12),
  )

# Small multiples ---------------------------------------------------------

#build out a similar dataset for North Carolina
nc_covid <- covid_time_series %>%
  filter(Province_State == 'North Carolina') %>%
  filter(Admin2 != 'Unassigned') %>% 
  filter(Admin2 != 'Out of NC') %>% 
  select(-UID, -iso2, -iso3, -code3, -Country_Region, -Lat, -Long_, -Combined_Key) %>% 
  pivot_longer(!c(FIPS,Admin2,Province_State), names_to = 'date', values_to = 'case_count') %>% 
  mutate(date = as.Date(date, format="%m/%d/%y"))

#calculate new cases and rolling average for each county
nc_covid <- nc_covid %>% 
  group_by(Admin2) %>%
  mutate(new_cases = case_count - lag(case_count,1)) %>% 
  mutate(rolling_new = round(rollmean(new_cases, 7, na.pad = TRUE, align="right")))

#charge for different counties
nc_covid %>%
  filter(date > '2020-03-01') %>%
  filter(Admin2 == 'Mecklenburg') %>% 
  ggplot(aes(date, rolling_new))+
  geom_line(color = '#2b8cbe') +
  scale_x_date(date_breaks = '2 months', date_labels = "%b %y") +
  labs(title = "Mecklenburg COVID-19 case counts over time",
       caption = "SOURCE: Johns Hopkins University",
       x = "",
       y = "Case count") +
  theme(strip.text.x = element_text(size = 10),
        strip.background.x = element_blank(),
        axis.line.x = element_line(color="black", size = 0.25),
        axis.line.y = element_line(color="black", size = 0.25),
        panel.grid.major.x = element_line( color="grey", size = 0.25 ) ,
        panel.grid.major.y = element_line( color="grey", size = 0.25 ) , 
        axis.ticks = element_blank(),
        panel.background = element_blank(),
        plot.title = element_text(size = 12),
  )

#what happens if we view all counties at once.
nc_covid %>%
  filter(date > '2020-03-01') %>%
  ggplot(aes(date, rolling_new, color=Admin2) ) +
  geom_line() +
  scale_x_date(date_breaks = '2 months', date_labels = "%b %y") +
  labs(title = "COVID-19 case counts over time",
       caption = "SOURCE: Johns Hopkins University",
       x = "",
       y = "Case count") +
  theme(strip.text.x = element_text(size = 10),
        strip.background.x = element_blank(),
        axis.line.x = element_line(color="black", size = 0.25),
        axis.line.y = element_line(color="black", size = 0.25),
        panel.grid.major.x = element_line( color="grey", size = 0.25 ) ,
        panel.grid.major.y = element_line( color="grey", size = 0.25 ) , 
        axis.ticks = element_blank(),
        panel.background = element_blank(),
        plot.title = element_text(size = 12),
        legend.position = "none"
  )

#use geofacet to show the trends across the state
nc_covid %>% 
  filter(date > '2020-03-01') %>%
  mutate(Admin2 = str_to_title(Admin2)) %>% 
  ggplot(aes(date, rolling_new) ) +
  geom_line(color = '#2b8cbe') +
  facet_geo(~Admin2, grid = "us_nc_counties_grid1") +
  scale_x_continuous(labels = NULL) +
  labs(title = "Rolling average of new cases in NC",
       caption = "SOURCE: Johns Hopkins University",
       x = NULL,
       y = NULL) +
  theme(strip.text.x = element_text(size = 6),
        strip.background.x = element_blank(),
        axis.ticks = element_blank(),
        axis.text = element_text(size = 6),
        panel.background = element_blank(),
        plot.title = element_text(size = 12),
  )

#same thing, but with a variable axis
nc_covid %>% 
  filter(date > '2020-03-01') %>%
  mutate(Admin2 = str_to_title(Admin2)) %>% 
  ggplot(aes(date, rolling_new) ) +
  geom_line(color = '#2b8cbe') +
  facet_geo(~Admin2, grid = "us_nc_counties_grid1", scales="free_y") +
  scale_x_continuous(labels = NULL) +
  labs(title = "Rolling average of new cases in NC, variable axis",
       caption = "SOURCE: Johns Hopkins University",
       x = NULL,
       y = NULL) +
  theme(strip.text.x = element_text(size = 6),
        strip.background.x = element_blank(),
        axis.ticks = element_blank(),
        axis.text = element_text(size = 6),
        panel.background = element_blank(),
        plot.title = element_text(size = 12),
  )

#move up the date filter
#same thing, but with a variable axis
nc_covid %>% 
  filter(date > '2021-01-14') %>%
  mutate(Admin2 = str_to_title(Admin2)) %>% 
  ggplot(aes(date, rolling_new) ) +
  geom_line(color = '#2b8cbe') +
  facet_geo(~Admin2, grid = "us_nc_counties_grid1", scales="free_y") +
  scale_x_continuous(labels = NULL) +
  labs(title = "Rolling average of new cases in NC",
       caption = "SOURCE: Johns Hopkins University",
       x = NULL,
       y = NULL) +
  theme(strip.text.x = element_text(size = 6),
        strip.background.x = element_blank(),
        axis.ticks = element_blank(),
        axis.text = element_text(size = 6),
        panel.background = element_blank(),
        plot.title = element_text(size = 12),
  )

# Creating scatter plots --------------------------------------------------

#TBD