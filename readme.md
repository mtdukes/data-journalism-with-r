# Data journalism with R

The statistical programming language R is quickly becoming one of the standard tools for data journalists around the world. This workshop will help you get started with a few foundational steps for importing, cleaning and analyzing data using R, the desktop development environment RStudio and several common libraries for working with data.

In this repository, you'll find both the data we'll be working with and the full R script for our in-class exercises for your review.

## Getting started
Download and unzip this file, which contains the notes and data we'll be using in today's workshop. You might want to move the unzipped file to your Desktop or some other location that's easy for you to find.

After starting RStudio, click "File" > "New File" > "R Script" in the menu to start a new script. Then go ahead and "Save As..." to give it a name. You should get in the habit of saving your work often.

At the top of your script, write a quick comment that tells you something about what your new script does. Starting each line with a `#` character will ensure this line is not executed when you run your code.

    #R script for the Duke Data Journalism Lab
    #workshop on Feb. 19, 2021

To save us some headaches down the road, we want to tell RStudio where we want to do our work by setting our working directory. It's also good practice to comment your code as you go for readability.

    #set working directory to the data folder of the downloaded repository
    setwd("~/Desktop/data-journalism-with-r/data")

Execute the code by clicking "Run" or with **CMD + Enter**.

R has a lot of great, basic functionality built in. But an entire community of R developers has created a long list of packages that give R a wealth of additional tricks. One of the most popular is the [Tidyverse](https://www.tidyverse.org/), a collection of packages designed for data science. Let's install a few of those packages. **This step we'll only have to do once.**

    #install the tidyverse package
    install.packages("tidyverse")
    install.packages("knitr")
    install.packages("stringr")
    install.packages("janitor")

Then load them from our library. **This step we'll have to do each time we start R or start a new workspace.**

    #load our packages from our library into our workspace
    library(tidyverse)
    library(knitr)
    library(stringr)
    library(janitor)

The data we'll be working with today contains the North Carolina recipients of loans through the federal Small Business Administration's [Paycheck Protection Program](https://www.sba.gov/funding-programs/loans/coronavirus-relief-options/paycheck-protection-program/ppp-data). Load it in with a function from our Tidyverse package.

    #load in our fresh data
    ppp <- read_csv('ppp_nc20210201.csv')

Take note that in your "Environment" window (by default in the top left), you should be able to see your ppp dataframe with 141,837 rows and 50 variables.

## Basic gut checks

Before we start working with our data in earnest, let's get to know our data a little bit. You can click on the dataset in your environment window to view it in a new window, much like you would in Excel or some other spreadsheet software.

We can see a number of columns that are pretty self explanatory. Some less so. We'll need to explore those as we go. Navigate back to your script window, and let's do a few things to make sure our head is on straight. For this section, we'll be using the "pipe," which looks like this `%>%` to chain together operations on our data.

First, let's check to make sure we got it all through the load.

```R
#how many rows do we have?
ppp %>% 
  nrow()
  ```

And make sure we're only looking at borrowers in North Carolina. And let's check that with more than one variable.

```R
#are we only looking at NC?
ppp %>% 
  count(BorrowerState)
  
ppp %>% 
  count(ProjectState)
  ```

Check how much money we're talking about here?

```R
#what's our total loan value?
ppp %>% 
  summarize(total = sum(InitialApprovalAmount))
  ```

Let's see how much are borrowers getting on average vs. the typical/middle value

```R
#what about the average?
ppp %>% 
  summarize(avg = mean(InitialApprovalAmount))
  ```

```R
#what's the median?
ppp %>% 
  summarize(total = median(InitialApprovalAmount))
```

We're going to be working with some large numbers here, so let's disable scientific notation so we can read the output a little better.

```R
#disable scientific notation
options(scipen=999)
```

Now let's look at how got the largest and smallest loans, and simplify our output a bit to make it a little more readable.

```R
#who got the largest loan?
ppp %>% 
  arrange(desc(InitialApprovalAmount)) %>%
  select(BorrowerName, BorrowerCity, InitialApprovalAmount) %>% 
  head() %>% 
  kable('simple')
  ```

Conversely, who got the smallest loan amount. That might be a little weird!

```R
#who got the smallest loan?
ppp %>% 
  arrange(InitialApprovalAmount) %>%
  select(BorrowerName, BorrowerCity, InitialApprovalAmount) %>% 
  head() %>% 
  kable('simple')
  ```

Although we can see them in the big table view, it might be helpful to get a list of all of our fields in one place so we can see what's there – and what we might need to ask about during our reporting.

```R
#give me a rundown of the column names
ppp %>% 
  names()
  ```

## Cleaning and grouping

Now that we have a good idea of what's here, let's see if we can answer some basic questions about the geographic distribution of these loans. Let's start with the county, which looks pretty clean

```R
#group by county
ppp %>% 
  count(ProjectCountyName, name = 'loan_count') %>% 
  arrange(desc(loan_count)) %>% 
  kable('simple')
  ```

But the city is a little different. Notice how often names are misspelled and inconsistent.

```R
#group by city
ppp %>% 
  count(ProjectCity, name = 'loan_count') %>% 
  arrange(desc(loan_count)) %>% 
  kable('simple')
  ```

One thing we can do to fix that is to create a "clean" column, where we generate a little code to fix our wonky data. Here, we are essentially overwriting our old data.

```R
ppp <- ppp %>% 
  mutate(ProjectCity_clean = toupper(ProjectCity)) %>% 
  mutate(ProjectCity_clean = str_remove_all(ProjectCity_clean, '\\.')) %>% 
  relocate(ProjectCity_clean, .after = ProjectCity)
  ```
 
There are other ways to clean data that we'll get to in future lessons. But for now, we might make a decision that this is a bit too dirty to work with for the time being.

## Joining other data

Among the fields in our data is a column called `NAICSCode`, which is the code assigned by the North American Industry Classification System. It basically describes what type of business the company is in. The codes are standardized, meaning we can use them to find out how funds are distributed across industry types, but we'll need to join them up to do that.

The data set we'll be joining is a lookup table using the first two digits of the NAICS code, which describes the top-level industry type.

First, let's make sure we have a column to match on.

```R
ppp <- ppp %>%
  mutate(NAICS_initial = strtoi(substr(NAICSCode, start = 1, stop = 2)))
  ```

Then, let's take join and group our industry codes accordingly.

```R
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
  ```

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