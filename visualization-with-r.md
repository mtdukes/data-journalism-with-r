
# Data visualization with R

In this repository, you'll find both the data we'll be working with and the full R script for our in-class exercises for your review.

## Getting started
[Download and unzip this file](https://github.com/mtdukes/data-journalism-with-r/archive/main.zip), which contains the notes and data we'll be using in today's workshop. You might want to move the unzipped file to your Desktop or some other location that's easy for you to find. The full, detailed code for this lesson [is available here](https://github.com/mtdukes/data-journalism-with-r/blob/main/data/workshop20210326.R).

After starting RStudio, click "File" > "New File" > "R Script" in the menu to start a new script. Then go ahead and "Save As..." to give it a name. You should get in the habit of saving your work often.

At the top of your script, write a quick comment that tells you something about what your new script does. Starting each line with a `#` character will ensure this line is not executed when you run your code.

```R
#R script for the Duke Data Journalism Lab
#workshop on March 26, 2021
```

To save us some headaches down the road, we want to tell RStudio where we want to do our work by setting our working directory. It's also good practice to comment your code as you go for readability.

```R
#set working directory to the data folder of the downloaded repository
setwd("~/Desktop/data-journalism-with-r/data")
```

Execute the code by clicking "Run" or with **CMD + Enter**.

We should have most of our packages already install, but we'll use a few more.

```R
#install other packages
install.packages('zoo')
install.packages('geofacet')
```

Load our [Tidyverse](https://www.tidyverse.org/) package and any others. **This step we'll have to do each time we start R or start a new workspace.**

```R
#load our packages from our library into our workspace
library(tidyverse)
library(knitr)
library(zoo)
library(geofacet)
library(stringr)
```

---
***Note:** If you get an error about R not being able to locate a package, you may have to install it if you didn't do this in our last workshop:*

```R
#install the tidyverse package
install.packages("tidyverse")
install.packages("knitr")
install.packages("zoo")
install.packages("geofacet")
install.packages("stringr")
```
---

The data we'll be working with today comes from [Johns Hopkins University's COVID-19 dataset](https://github.com/CSSEGISandData), which has become a go-to source of data on the spread of the virus. Specifically, we'll be using [time-series data on case counts by county](https://github.com/CSSEGISandData/COVID-19/blob/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_US.csv). Load it in with a function from our Tidyverse package.

```R
#load in our fresh data
covid_time_series <- read_csv('jhu_covid.csv')
```

Take note that in your "Environment" window (by default in the top left), you should be able to see your `covid_time_series` dataframe with 3,340 rows and 440 variables.

## Basic gut checks

Before we start working with our data in earnest, let's get to know our data a little bit. You can click on the dataset in your environment window to view it in a new window, much like you would in Excel or some other spreadsheet software.

We can see a number of columns that are pretty self explanatory. Some less so. We'll need to explore those as we go. Navigate back to your script window, and let's do a few things to make sure our head is on straight. For this section, we'll be using the "pipe," which looks like this `%>%` to chain together operations on our data.

First, let's check to make sure we got it all through the load.

```R
#count the total number of rows
covid_time_series %>% 
  nrow()
  ```

Let's focus on North Carolina.

```R
covid_time_series %>%
  filter(Province_State == 'North Carolina') %>% 
  nrow()
  ```

That should return a value of 102.

But wait! There are only 100 counties in North Carolina. So what's going on?

```R
#examine the county list for the NC data
#and put it in a nice table
covid_time_series %>%
  filter(Province_State == 'North Carolina') %>% 
  select(Admin2) %>% 
  kable('simple')
  ```

Looks like we've got two unexpected values: "Unassigned" and "Out of NC", so we'll need to make a note to filter those out in the future.

Now let's make sure this data roughly matches another source, just because we're paranoid.

```R
#count up the total number of cases for the last date
covid_time_series %>%
  filter(Province_State == 'North Carolina') %>% 
  summarize(across('3/25/21',sum))
```
Does that match the latest data from the [N.C. Department of Health and Human Services' COVID-19 dashboard](https://covid19.ncdhhs.gov/dashboard)?

## Change over time with a simple line chart

As you may have gathered from the "time series" element of this data, we probably want to take a look at change in COVID case counts over time. Let's simplify things by looking at one specific county – Durham.

```R
#create a durham only dataset and drop our unneeded columns
durham_covid <- covid_time_series %>%
  filter(Province_State == 'North Carolina' & Admin2 == 'Durham') %>% 
  select(-UID, -iso2, -iso3, -code3, -Country_Region, -Lat, -Long_, -Combined_Key)
```

We're going to be using ggplot, a library within the Tidyverse, to do some of our charting and graphing. But there's a formatting problem here: This data is current "wide." We need it to be "long" to conform to the formatting rules of the ggplot library (and for general readability). This will also allow us to format the dates correctly.

```R
#reformat our data from wide to long
#by telling our function what columns we don't want split
#and clean up our date column
durham_covid <- durham_covid %>% 
  pivot_longer(!c(FIPS,Admin2,Province_State), names_to = 'date', values_to = 'case_count') %>% 
  mutate(date = as.Date(date, format="%m/%d/%y"))
```

Now, if you check the `durham_covid` dataframe, you'll see the 400-odd columns transform into 400-odd rows.

Using the ggplot package baked into Tidyverse, let's generate a simple plot of cases over time in Durham. After this runs, you should see this in the "Plots" window in the lower right-hand corner of your R Studio workspace.

```R
#plot the case count over time
durham_covid %>% 
  ggplot(aes(date, case_count))+
  geom_line()
```

Cool, but ugly. Let's introduce a few styling elements to label and clean it up.

```R
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
```

We can certainly see some patterns in this data, but it's a difficult. That's because we know that the COVID-19 case counts grow over time. What we're more interested in is *how much* that count grows over time. So we need to look at *new cases* more closely.

To do that, we'll add a new column with the `lag` function.

```R
#calculate new cases as a new column
durham_covid <- durham_covid %>%
  mutate(new_cases = case_count - lag(case_count,1))
```

Now let's chart it again, just substituting our new cases for our case count.

```R
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
```

That's... spiky. And even more complicated. One way to smooth out the jitter is to take a rolling average, so we'll use a function from our Zoo package to calculate that average over 7 days.

```R
#calculate rolling average of new cases as a new column
durham_covid <- durham_covid %>%
  mutate(rolling_new = round(rollmean(new_cases, 7, na.pad = TRUE, align="right")))
  ```

With that column calculated, we can chart our case growth again – and see the trends much more clearly.

```R
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
```

## Patterns in small multiples

What if we want to take a much broader look than just Durham? We can, and it's easy.

We can use the same exact techniques and calculate these new columns for each of North Carolina's 100 counties. We'll start with a filtered, cleaned up set focusing on the whole state.

```R
#build out a similar dataset for North Carolina
nc_covid <- covid_time_series %>%
  filter(Province_State == 'North Carolina') %>%
  filter(Admin2 != 'Unassigned') %>% 
  filter(Admin2 != 'Out of NC') %>% 
  select(-UID, -iso2, -iso3, -code3, -Country_Region, -Lat, -Long_, -Combined_Key) %>% 
  pivot_longer(!c(FIPS,Admin2,Province_State), names_to = 'date', values_to = 'case_count') %>% 
  mutate(date = as.Date(date, format="%m/%d/%y"))
```

Now, let's use `lag` and `rollmean`, combined with `group_by`, to calculate our new columns.

```R
#calculate new cases and rolling average for each county
nc_covid <- nc_covid %>% 
  group_by(Admin2) %>%
  mutate(new_cases = case_count - lag(case_count,1)) %>% 
  mutate(rolling_new = round(rollmean(new_cases, 7, na.pad = TRUE, align="right")))
```

With that data, we can quickly build out individual charts for any county we want, like this.

```R
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
```

But let's go further. We can plot all of these counties on one chart, but that's... unhelpful.

```R
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
```

Instead of looking at everything on the same plot, let's use [small multiples](https://www.propublica.org/nerds/a-big-article-about-wee-things). This approach splits the chart across many different, smaller charts. We'll use some precision, but it will be much, much easier to examine.

We're shortcutting the styling here, but here goes. This should show up in your plot viewer, but it's probably worth pressing the "Zoom" button to pop the graphic out into a separate window.

```R
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
```
Pretty interesting. But the reality is that the huge population difference between rural counties and others like Wake and Mecklenburg really blows up are scale. So let's introduce a variable axis.

```R
#same thing, but with a variable axis
nc_covid %>% 
  filter(date > '2020-03-01') %>%
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
```

Now we have a new problem! The winter spike was so high, it's essentially blowing out all the other changes. So maybe we focus on what's happened lately by using a simple date filter. Here, we're using Jan. 14, 2021, the date residents 65 and older became eligible for the vaccine.

```R
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
```

## Relationships with scatter plots

TBD

## Glossary
### Assignment function
The sequence of characters `<-` used to assign values to an object.

### Comment
A line in your script beginning with `#` that won't be executed. Used to 

### Dataframe
Sometimes abbreviated "df," a dataframe is R parlance for a dataset of vectors stored a list.

### Execute
Command your script to run a line of your code. Shortcut: **CMD/CTRL + Enter**

### List
A set of objects that can contain things like variables or dataframes.

### Package
An enhancements to R that adds additional functionality to your workspace.

### Pipe
The sequence of characters `%>%` used to chain together different functions for more complex operations. Shortcut: **CMD/CTRL + Shift + M**

### Script
A file with the suffix ".R" where you write your R code.

### String
A sequence of characters not interpreted as a numeric variable.

### Type
Definition for your variable that describes its format. For example: numeric or character.

### Vector
A variable.

### Workspace
The area in your computer's memory where you'll be working, and where are your data, functions, packages, etc. are loaded.

## Additional resources
* [RStudio cheatsheets](https://rstudio.com/resources/cheatsheets/)