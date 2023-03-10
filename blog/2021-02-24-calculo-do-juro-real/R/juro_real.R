
# Coleta de dados ---------------------------------------------------------

# Expectativas Selic e IPCA anuais - BCB
dados_focus_anual <- rbcb::get_market_expectations(
  type = "annual",
  indic = c("Selic", "IPCA"),
  start_date = "1999-01-01"
  )

# Expectativas IPCA em 12 meses - BCB
dados_focus_12m <- rbcb::get_market_expectations(
  type = "inflation-12-months", 
  indic = "IPCA",
  start_date = "1999-01-01"
  )

# Swaps DI pré 360
dados_ipea <- ipeadatar::ipeadata("BMF12_SWAPDI36012")



# Tratamento de dados -----------------------------------------------------

# Proxy para Juro neutro
neutro <- dados_focus_anual |>
  dplyr::filter(
    baseCalculo == 0, 
    DataReferencia == lubridate::year(Data) + 3
    ) |>
  tidyr::pivot_wider(
    id_cols = c("Data", "DataReferencia"), 
    names_from = "Indicador", 
    values_from = "Mediana"
    ) |>
  dplyr::group_by(data = lubridate::floor_date(Data, unit = "month")) |>
  dplyr::summarise(
    neutro = mean(
      x = (((1 + (Selic / 100)) / (1 + (IPCA / 100))) - 1) * 100, 
      na.rm = TRUE
      )
    )

# Calcula juro real
juro_real <- dplyr::left_join(
  x = dados_focus_12m |>
    dplyr::filter(baseCalculo == 0 & Suavizada == "S") |>
    dplyr::group_by(data = lubridate::floor_date(Data, unit = "month")) |>
    dplyr::summarise(ipca_exp = mean(x = Mediana, na.rm = TRUE)),
  y = dplyr::select(dados_ipea, "data" = "date", "swaps" = "value"),
  by = "data"
  ) |>
  dplyr::mutate(
    data = data,
    juro_real = (((1 + (swaps / 100)) / (1 + (ipca_exp / 100))) - 1) * 100,
    .keep = "none"
    )

# Cruza dados de juros
conducao <- dplyr::left_join(x = neutro, y = juro_real, by = "data") |> 
  tidyr::drop_na()



# Visualização de dados ---------------------------------------------------

# Gráfico dos juros reais e neutro
set.seed(1984)
regimes <- conducao |>
  tidyr::drop_na() |> 
  dplyr::mutate(
    conducao = dplyr::if_else(
      pmin(neutro, juro_real) == neutro,
      "Contracionista",
      "Expansionista"
      ),
    diff = abs(neutro - juro_real)
    ) |>
  dplyr::group_by(conducao) |> 
  dplyr::filter(diff == max(diff)) |> 
  dplyr::ungroup()

g1 <- ggplot2::ggplot(data = conducao) +
  ggplot2::aes(x = data) +
  ggplot2::geom_hline(yintercept = 0, linetype = "dashed") +
  ggplot2::geom_ribbon(
    mapping = ggplot2::aes(ymin = pmin(neutro, juro_real), ymax = juro_real),
    alpha = 0.3,
    fill = "#b22200"
      ) +
  ggplot2::geom_ribbon(
    mapping = ggplot2::aes(ymin = pmin(neutro, juro_real), ymax = neutro), 
    alpha = 0.3,
    fill = "#282f6b"
      ) +
  ggplot2::geom_line(
    mapping = ggplot2::aes(y = neutro, color = "Juro neutro"),
    size = 1
    ) +
  ggplot2::geom_line(
    mapping = ggplot2::aes(y = juro_real, color = "Juro real ex-ante"),
    size = 1
    ) +
  ggplot2::coord_cartesian(
    clip = "off",
    xlim = c(min(conducao$data), max(conducao$data) + months(12))
    ) +
  ggrepel::geom_label_repel(
    mapping = ggplot2::aes(
      y     = neutro,
      label = format(round(neutro, 2), big.mark = ".", decimal.mark = ",", nsmall = 2)
      ),
    nudge_x        = 0.2,
    nudge_y        = 0,
    color          = "white",
    fill           = "#282f6b",
    fontface       = "bold",
    segment.colour = NA,
    label.size     = 0,
    data           = dplyr::filter(tidyr::drop_na(conducao, neutro), data == max(data))
    ) +
  ggrepel::geom_label_repel(
    mapping = ggplot2::aes(
      y     = juro_real,
      label = format(round(juro_real, 2), big.mark = ".", decimal.mark = ",", nsmall = 2)
      ),
    nudge_x        = 0.1,
    nudge_y        = 0,
    color          = "white",
    fill           = "#b22200",
    fontface       = "bold",
    segment.colour = NA,
    label.size     = 0,
    data           = dplyr::filter(tidyr::drop_na(conducao, juro_real), data == max(data))
    ) +
  ggrepel::geom_text_repel(
    mapping = ggplot2::aes(
      y     = mean(c(neutro, juro_real)),
      label = "Expansionista"
      ),
    color              = "#282f6b",
    fontface           = "bold",
    min.segment.length = 0, 
    nudge_y            = 5, 
    nudge_x            = -500,
    segment.size       = 0.7,
    arrow              = ggplot2::arrow(length = ggplot2::unit(0.05, "npc")),
    segment.curvature  = 0.5,
    segment.angle      = 90,
    segment.ncp        = 3,
    segment.square     = FALSE,
    segment.inflect    = FALSE,
    data               = dplyr::filter(regimes, conducao == "Expansionista")
    ) +
  ggrepel::geom_text_repel(
    mapping = ggplot2::aes(
      y     = mean(c(neutro, juro_real)) - 4,
      label = "Contracionista"
      ),
    color              = "#b22200",
    fontface           = "bold",
    min.segment.length = 0, 
    nudge_y            = 3, 
    nudge_x            = 1200,
    segment.size       = 0.7,
    arrow              = ggplot2::arrow(length = ggplot2::unit(0.05, "npc")),
    segment.curvature  = 0.5,
    segment.angle      = 90,
    segment.ncp        = 3,
    segment.square     = FALSE,
    segment.inflect    = FALSE,
    data               = dplyr::filter(regimes, conducao == "Contracionista")
    ) +
  ggplot2::scale_color_manual(values = c("#282f6b", "#b22200")) +
  ggplot2::scale_y_continuous(
    labels = scales::label_number(big.mark = ".", decimal.mark = ",")
    ) +
  ggplot2::scale_x_date(date_breaks = "3 years", date_labels = "%Y") +
  ggplot2::labs(
    title    = "Brasil: Condução da Política Monetária",
    y        = "% a.a.",
    x        = NULL,
    color    = NULL,
    caption  = paste0(
      "**Dados**: BCB e IPEADATA | **Elaboração**: Fernando da Silva<br>",
      "**Nota**: proxy de juro neutro como a Selic esperada t+3 deflacionada ",
      "pela inflação t+3"
      )
    ) +
  ggplot2::theme_light(base_size = 16) +
  ggplot2::theme(
    plot.title      = ggplot2::element_text(face = "bold"),
    plot.caption    = ggtext::element_textbox_simple(
      margin = ggplot2::margin(10, 0, 0, 0)
      ),
    plot.title.position   = "plot",
    plot.caption.position = "plot",
    axis.text             = ggplot2::element_text(face = "bold"),
    axis.title            = ggplot2::element_text(face = "bold"),
    legend.text           = ggplot2::element_text(face = "bold"),
    legend.position       = c(0.7, 0.9),
    legend.key            = ggplot2::element_blank(),
    legend.background     = ggplot2::element_blank(),
    legend.direction      = "horizontal"
    )

# Salvar imagem
# if (!dir.exists("imgs")) {dir.create("imgs")}
# ggplot2::ggsave(
#   filename = "imgs/conducao.png",
#   plot     = g1,
#   width    = 7.2,
#   height   = 4
#   )
