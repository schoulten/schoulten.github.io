Séries temporais: detectando mudança de média
================
Fernando da Silva, Cientista de Dados
20 de novembro de 2021

### Introdução

Ao analisar séries temporais pode ser útil identificar pontos de mudança
em seu comportamento, utilizando métodos de detecção para tal. Existem
diversos métodos e algoritmos para implementar esse tipo de análise,
desde simples cálculos envolvendo erro quadrático médio até abordagens
Bayesianas. Neste texto mostramos uma maneira simples de detectar pontos
de mudança em uma série temporal com o método de Taylor (2000).

### Metodologia

O método desenvolvido por Taylor (2000), conforme mencionado, se baseia
em um cálculo simples de erro quadrático médio (EQM) para identificar
quando uma mudança na série ocorreu. A ideia geral é separar a série
temporal em segmentos e calcular o EQM dos mesmos para identificar
pontos de mudança, considerando o valor que minimiza o EQM. Formalmente:

<img src="imgs/ts_eqm.PNG" width="50%" style="display: block; margin: auto;" />

onde:

<img src="imgs/ts_eqm_x.PNG" width="50%" style="display: block; margin: auto;" />

### Exemplo no R

A implementação do método de detecção de pontos de mudança de média,
desenvolvido por Taylor (2000), é feita recursivamente pelo pacote
`ChangePointTaylor` no R.

Neste exemplo aplicamos o método para a série anual da Produtividade
total dos fatores da economia brasileira, variável disponível no
*dataset* da Penn World Table 10.0.

``` r
# Pacotes -----------------------------------------------------------------

library(ChangePointTaylor) # CRAN v0.1.1
library(pwt10)             # CRAN v10.0-0
library(dplyr)             # CRAN v1.0.7
library(tidyr)             # CRAN v1.1.4
library(ggplot2)           # CRAN v3.3.5
library(scales)            # CRAN v1.1.1
library(ggtext)            # CRAN v0.1.1


# Dados -------------------------------------------------------------------

# Tibble com dados da Produtividade total dos fatores - Brasil (2017 = 1)
tfp_br <- pwt10::pwt10.0 %>%
  dplyr::filter(isocode == "BRA") %>%
  dplyr::select(.data$year, .data$rtfpna) %>%
  tidyr::drop_na() %>%
  dplyr::as_tibble()

tfp_br
```

    ## # A tibble: 66 x 2
    ##     year rtfpna
    ##    <int>  <dbl>
    ##  1  1954  0.805
    ##  2  1955  0.819
    ##  3  1956  0.815
    ##  4  1957  0.851
    ##  5  1958  0.862
    ##  6  1959  0.876
    ##  7  1960  0.897
    ##  8  1961  0.976
    ##  9  1962  0.981
    ## 10  1963  1.01 
    ## # ... with 56 more rows

``` r
# Aplicar método de detecção de mudança (Taylor, 2000) --------------------

# Informar vetor de valores da série e
# vetor de nomes (usalmente a data correspondente ao valor)
change_points <- ChangePointTaylor::change_point_analyzer(
  x      = tfp_br$rtfpna,
  labels = tfp_br$year
  )

dplyr::as_tibble(change_points)
```

    ## # A tibble: 9 x 6
    ##   change_ix label `CI (95%)`    change_conf  From    To
    ##       <dbl> <int> <chr>               <dbl> <dbl> <dbl>
    ## 1         8  1961 (1961 - 1961)       0.998 0.847 1.01 
    ## 2        15  1968 (1968 - 1968)       0.966 1.01  1.15 
    ## 3        19  1972 (1972 - 1972)       0.998 1.15  1.33 
    ## 4        29  1982 (1979 - 1984)       0.999 1.33  1.25 
    ## 5        37  1990 (1989 - 1990)       0.967 1.25  1.14 
    ## 6        41  1994 (1994 - 1995)       0.94  1.14  1.18 
    ## 7        46  1999 (1999 - 1999)       0.993 1.18  1.10 
    ## 8        54  2007 (2005 - 2012)       0.997 1.10  1.13 
    ## 9        62  2015 (2015 - 2015)       0.991 1.13  0.998

``` r
# Visualização de resultados ----------------------------------------------

# Gera gráfico ggplot2
tfp_br %>%
  ggplot2::ggplot(ggplot2::aes(x = year, y = rtfpna)) +
  ggplot2::geom_line(size = 2, color = "#282f6b") +
  ggplot2::geom_vline(
    xintercept = change_points$label,
    color      = "#b22200",
    linetype   = "dashed",
    size       = 1
  ) +
  ggplot2::scale_x_continuous(breaks = scales::extended_breaks(n = 20)) +
  ggplot2::scale_y_continuous(labels = scales::label_number(decimal.mark = ",", accuracy = 0.1)) +
  ggplot2::labs(
    title    = "Produtividade Total dos Fatores - Brasil",
    subtitle = "Preços nacionais constantes (2017 = 1)<br>Linhas tracejadas indicam pontos de mudança de média (Taylor, 2000)",
    y        = "PTF",
    x        = NULL,
    caption  = "**Dados**: Penn World Table 10.0 | **Elaboração**: Fernando da Silva"
  ) +
  ggplot2::theme_light() +
  ggplot2::theme(
    panel.grid       = ggplot2::element_blank(),
    axis.text        = ggtext::element_markdown(size = 12, face = "bold"),
    axis.title       = ggtext::element_markdown(size = 12, face = "bold"),
    plot.subtitle    = ggtext::element_markdown(size = 16, hjust = 0),
    plot.title       = ggtext::element_markdown(
      size   = 30,
      face   = "bold",
      colour = "#282f6b",
      hjust  = 0,
    ),
    plot.caption     = ggtext::element_textbox_simple(
      size   = 12,
      colour = "grey20",
      margin = ggplot2::margin(10, 5.5, 10, 5.5)
    )
  )
```

<img src="change_point_detect_files/figure-gfm/unnamed-chunk-3-1.png" width="100%" style="display: block; margin: auto;" />

### Referências

Taylor, W. A. (2000). Change-point analysis: a powerful new tool for
detecting changes.
