---
title: "meedr: MacroEconomic Expectations Data in R using the Central Bank of Brazil API"
date: 2021-03-13
description: Quick and easy access to market expectations data of the Focus report from Central Bank of Brazil, through the Expectations System API.
menu:
  sidebar:
    name: meedr
    identifier: meedr
    parent: rstats
    weight: 10
---

Very happy to announce that meedr, my first package on R, is on its way to CRAN!

The goal of `meedr` is to provide quick and easy access to market expectations data to the main macroeconomic indicators in the Focus report, made available by the **Central Bank of Brazil** through the Expectations System data [API](https://olinda.bcb.gov.br/olinda/servico/Expectativas/versao/v1/aplicacao#!/recursos). This data comes from several financial institutions, such as: banks, brokers, funds, consultancies, etc.

The `meedr` package offers an R interface to the API and other advantages:

-   Use of a caching system with package `memoise` to speed up repeated requests of data;
-   User can utilize all cores of the machine (parallel computing) when fetching a large batch of time series.

## Installation

You can install the development version from GitHub with:

``` r
# install.packages("devtools")
devtools::install_github("schoulten/meedr")
```

## Features

-   [get\_monthly()](#get_monthly): Get data on monthly market expectations
-   [get\_quarterly()](#get_quarterly): Get data on quarterly market expectations
-   [get\_annual()](#get_annual): Get data on annual market expectations
-   [get\_inflation\_12m()](#get_inflation_12m): Get data on market expectations for inflation over the next 12 months
-   [get\_monthly\_top5()](#get_monthly_top5): Get data on monthly market expectations for the Top 5 indicators
-   [get\_annual\_top5()](#get_annual_top5): Get data on annual market expectations for the Top 5 indicators

## Example

These are some basic examples of using the package:

### get\_monthly()

``` r
library(meedr)

# Monthly market expectations for IPCA indicator
meedr::get_monthly(
  indicator      = "IPCA",
  first_date     = Sys.Date()-30,
  reference_date = format(Sys.Date(), "%m/%Y"),
  be_quiet       = TRUE
  )
```

### get\_quarterly()

``` r
# Quarterly market expectations for GDP indicator
meedr::get_quarterly(
  indicator      = "PIB Total",
  first_date     = "2021-01-01",
  reference_date = paste0(lubridate::quarter(Sys.Date()), "/", lubridate::year(Sys.Date())),
  be_quiet       = TRUE
  )
```

### get\_annual()

``` r
# Annual market expectations for SELIC and exchange rate (BRL) indicator
meedr::get_annual(
  indicator      = c("Meta para taxa over-selic", "Taxa de câmbio"),
  reference_date = format(Sys.Date(), "%Y"),
  be_quiet       = TRUE
  )
```

### get\_inflation\_12m()

``` r
# Inflation over the next 12 months
# First, and a suggestion, run this for using parallel computing:
future::plan(future::multisession, workers = floor(future::availableCores()/2))
meedr::get_inflation_12m(
  indicator   = c("IGP-DI", "IGP-M", "INPC", "IPA-DI", "IPA-M", "IPCA", "IPCA-15", "IPC-FIPE"),
  smoothed    = "yes",
  be_quiet    = FALSE, # display messages
  do_parallel = TRUE # turn on parallel computing
  )
```

### get\_monthly\_top5()

``` r
# Monthly market expectations for IGP-M indicator (Top 5 Focus)
meedr::get_monthly_top5(
  indicator  = "IGP-M",
  first_date = NULL, # get all data to current date
  calc_type  = "long",
  be_quiet   = TRUE
  )
```

### get\_annual\_top5()

``` r
# Annual market expectations for SELIC indicator (Top 5 Focus)
meedr::get_annual_top5(
  indicator   = "Meta para taxa over-selic",
  detail      = "Fim do ano",
  be_quiet    = TRUE,
  use_memoise = FALSE # disable caching system
  )
```

## Data visualization

Now we are going to use this data to make this nice graph:

{{< img src="/posts/r/meedr/img/inflation_12m.jpg" align="center" width="750" >}}
{{< vs 2>}}
First we load some packages that we will use and then we download the expected inflation data for the next 12 months.

``` r
# Load packages
library(tidyverse)

# Get market expectations for inflation over the next 12 months
inflation <- meedr::get_inflation_12m(
  indicator   = "IPCA",
  first_date  = "2017-05-01",
  smoothed    = "yes"
  )
```
{{< vs 2>}}
We now create the line graph using the `ggplot2` package.

``` r
# Creating a theme
theme_fortie <- theme(
  panel.background   = element_rect(fill = "#acc8d4", colour = "#acc8d4"),
  panel.grid.minor   = element_blank(),
  panel.grid.major   = element_line(colour = "#e8f9ff"),
  plot.background    = element_rect(fill = "#8abbd0"),
  plot.title         = element_text(color = "midnightblue", size = 18, face = "bold"),
  plot.subtitle      = element_text(color = "gray20", size = 12, face = "bold"),
  plot.caption       = element_text(color = "grey20", size = 11, face = "bold"),
  axis.line          = element_line(colour = "black", linetype = "dashed"),
  axis.line.x.bottom = element_line(colour = "black"),
  axis.text.x        = element_text(color = "grey20", size = 11, face = "bold"),
  axis.text.y        = element_text(color = "grey20", size = 11, face = "bold"),
  axis.title.y       = element_text(color = "grey20", size = 12, face = "bold"),
  legend.text        = element_text(color = "gray20", size = 12, face = "bold"),
  legend.position    = c(0.9,0.15),
  legend.background  = element_blank(),
  legend.key         = element_blank()
)

# Plot
inflation %>%
  ggplot(aes(x = date)) +
  geom_line(aes(y = median, colour = "IPCA"), size = 1) +
  geom_line(aes(y = median - sd), size = .5, colour = "darkblue") +
  geom_line(aes(y = median + sd), size = .5, colour = "darkblue") +
  geom_ribbon(aes(ymin = median - sd, ymax = median + sd), alpha = 0.2, fill = "darkblue") +
  scale_colour_manual('', values = c("IPCA" = "red")) +
  scale_x_date(breaks = scales::date_breaks("7 months"), labels = scales::date_format("%m/%Y")) +
  scale_y_continuous(breaks = seq(from = 0, to = 5, by = 1.5), limits = c(0, 5.5)) +
  theme_fortie +
  labs(
    x        = NULL,
    y        = "%",
    title    = "Brazil: Market expectations for inflation over the \nnext 12 months",
    subtitle = "Smoothed median and standard deviation",
    caption  = "fortietwo.com"
  )

```
{{< vs 2>}}

And that's it!

The process of developing a package is a lot of learning and enrichment. Soon I intend to increase the package with new utilities. In the meantime, feel free to use and test the package, I will be happy to receive any feedback!
{{< vs 2>}}

## GitHub repo

Link: https://github.com/schoulten/meedr

<script type="text/javascript" src="https://cdnjs.buymeacoffee.com/1.0.0/button.prod.min.js" data-name="bmc-button" data-slug="schoulten" data-color="#40DCA5" data-emoji=""  data-font="Cookie" data-text="Buy me a coffee" data-outline-color="#000000" data-font-color="#ffffff" data-coffee-color="#FFDD00" ></script>
