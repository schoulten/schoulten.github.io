---
title: "Como calcular a taxa de juros real da economia brasileira?"
date: 2021-02-24
description: Cálculo da taxa de juros real pelos conceitos ex-ante e ex-post
menu:
  sidebar:
    name: Taxa de juros real
    identifier: juro-real
    parent: macroeconomia
    weight: 40
---

O dinheiro existe há bastante tempo e, geralmente, pagamos para poder usar o dinheiro e/ou poupança de outra pessoa (afinal, não existe almoço grátis). O preço dessa troca, entre o credor e o devedor, é o que usualmente se chama de juros. Também é comum que essa taxa, chamada de juros nominal, seja positiva e definida como um referencial pelo Banco Central de cada país, constituindo um dos principais instrumentos de controle da inflação.

Sabendo que a taxa de juros nominal é um preço, logo, há motivos para deflacioná-lo por um índice de correção de preços como o IPCA, por exemplo, de forma semelhante ao que fazemos quando é necessário "corrigir" o valor de um imóvel que irá à venda. O resultado dessa operação é o que é chamado de taxa de juros real, ou seja, a taxa nominal deflacionada pela taxa de inflação.

Existem basicamente duas perspectivas sobre a taxa de juros real: pelo conceito ex-post e pelo conceito ex-ante. No primeiro caso olhamos o comportamento dos juros no período passado, geralmente usando valores acumulados em 12 meses, o que nos permite verificar a tendência de juros real da economia; enquanto que no segundo caso é o oposto, estamos interessados em verificar o comportamento do juros real à frente, tomando como base expectativas de agentes de mercado, assim é possível identificar como é esperado o comportamento dos juros no futuro.

De forma mais visual, esses conceitos podem se traduzir em uma realidade da economia do país bastante impressionante se olharmos um período de tempo suficientemente grande, conforme a imagem abaixo:

{{< img src="/posts/macroeconomia/juro-real/img/juro_real.jpg" align="center" width="750" >}}

Explicados brevemente estes conceitos e dado uma prévia do resultado que queremos chegar, podemos partir para o cálculo das taxas. Para chegar ao resultado que determina o juros real da economia usamos a **equação de Fisher**, através da fórmula bem simples a seguir:

{{< math.inline >}}

<p>
(r_t =\frac{(1+i_t)}{(1+\pi_t)}-1)
</p>

{{</ math.inline >}}

Onde os termos significam:

{{< math.inline >}}

<p>
teste \(r_t = \text{taxa de juros real}\)
</p>

{{</ math.inline >}}

(i_t = \text{taxa de juros nominal}
(\pi_t = \text{taxa de inflação}



No caso da **taxa de juros real ex-ante**, opto aqui por utilizar a taxa do Swap DI-Pré 360 dias e as expectativas de IPCA esperado também de 1 ano à frente, provenientes da B3 e do boletim Focus/BCB respectivamente. Há outras maneiras de obter essa taxa, para uma discussão sobre o assunto recomendo [esse texto](https://blogdoibre.fgv.br/posts/juro-real-ex-ante-caindo-ou-subindo) do Bráulio Borges e Gilberto Borça Jr. Já no caso da **taxa de juros real ex-post** usamos a taxa Selic acumulada no mês anualizada em base de 252 dias úteis e o IPCA acumulado em 12 meses, provenientes do BCB e do IBGE respectivamente.

O que é necessário agora é obter esses dados e aplicar a equação de Fisher. A obtenção dos dados é bastante simples e rápida usando a linguagem R. Vamos usar as API's de três fontes públicas de dados (IPEADATA, BCB e IBGE). Vamos ao passo a passo:

{{< vs 2>}}
### 1. Pacotes

Primeiro temos que carregar os pacotes necessários. Usando o {pacman} já pulamos uma etapa que é verificar se os pacotes estão instalados e depois carregá-los, esse gerenciador de pacotes faz isso automaticamente através da função `p_load()`.

```
# Carregar/instalar pacotes
if(!require(pacman)) install.packages("pacman") # gerenciador de pacotes
pacman::p_load(
  "ipeadatar",                                  # para obter dados do IPEADATA
  "GetBCBData",                                 # para obter dados do BCB
  "sidrar",                                     # para obter dados do IBGE
  "tidyverse",                                  # para tratar dados/criar gráfico
  "ggrepel",                                    # para colocar legendas legais no gráfico
  "scales"                                      # para formatar valores
  )
```

{{< vs 2>}}
### 2. Definir parâmetros

O próximo passo é termos definido quais os dados que queremos obter, pois ao utilizar as API's precisamos apontar esses parâmetros para filtrar os dados que serão recebidos. A forma de definir isso varia conforme a API e/ou pacote utilizado, mas em geral é bastante simples, conforme a seguir.

```
# Parâmetros da API de dados do IPEADATA
api_ipea = c(
  swap          = "BMF12_SWAPDI36012",    # Taxa do swap DI-Pré 360 dias (média)
  ipca_prox_12m = "BM12_IPCAEXP1212"      # Expectativa média do IPCA, tx. acum. p/ os próx. 12 meses
  )

# Parâmetros da API de dados do BCB
api_bcb = c(selic = 4189)            # SELIC acumulada dos últimos 12 meses

# Parâmetros da API de dados do Sidra/IBGE
api_ibge = "/t/1737/n1/all/v/2265/p/all/d/v2265%202" # IPCA acumulado em 12 meses
```

{{< vs 2>}}
### 3. Coletar e tratar dados

Agora iremos utilizar os parâmetros para obter os dados das fontes indicadas. Além disso, fazemos pequenas tratativas dos dados para ficarem no formato desejado. São usadas três principais funções nessa etapa:

  1. `ipeadatar::ipeadata()` para baixar dados do IPEADATA
  2. `GetBCBData::gbcbd_get_series()` para baixar dados do BCB
  3. `sidrar::get_sidra()` para baixar dados do IBGE

Para entender detalhes destas funções recomendo fortemente consultar as respectivas documentações.

```
# Coletar dados do IPEADATA
dados_ipea <- ipeadata(code = api_ipea) %>%
  select(-c(uname, tcode)) %>% 
  pivot_wider(
    id_cols     = "date",
    names_from  = "code",
    values_from = "value"
    ) %>%
  rename(
    "swap"          = 2,
    "ipca_prox_12m" = 3,
    data            = date
    ) %>% 
  drop_na()

# Coletar dados do BCB
dados_bcb <- gbcbd_get_series(
    id         = api_bcb,
    first.date = min(dados_ipea$data)
    ) %>%
  select(
    data  = ref.date,
    selic = value
    )

# Coletar dados do Sidra/IBGE
dados_ibge <- get_sidra(api = api_ibge) %>%
  select(
    data          = "Mês (Código)",
    ipca_acum_12m = "Valor"
    ) %>%
  mutate(
    data = paste0(data, "01") %>% as.Date(format = "%Y%m%d")
    ) %>%
  drop_na()
```

{{< vs 2>}}
### 4. Calcular o juros real

Com os dados em mãos, podemos aplicar a equação de Fisher. O resultado final será um objeto "tibble/data.frame" com uma coluna de data, outra de valor da taxa de juros real e outra identificando se o valor é pelo conceito ex-ante ou ex-post.

```
# Cálculo
juros_real <- bind_rows(
  
  # Ex-ante
  dados_ipea %>%
    mutate(
      valor = (((1+(swap/100))/(1+(ipca_prox_12m/100)))-1)*100,  # Equação de Fisher
      id    = "Ex-ante"
      ) %>% 
    select(data, valor, id),
  
  # Ex-post
  dados_ibge %>%
    inner_join(
      dados_bcb, 
      by = "data"
      ) %>%
    mutate(
      valor = (((1+(selic/100))/(1+(ipca_acum_12m/100)))-1)*100,  # Equação de Fisher
      id    = "Ex-post") %>% 
    select(data, valor, id)
    
  )
```

{{< vs 2>}}
### 5. Criar um gráfico

Por fim vamos gerar um gráfico que mostra a tendência das duas séries. Eu gosto muito do pacote {ggplot2}, dá pra criar gráficos muito bonitos e com muita flexibilidade. O código fica um pouco "extensivo", mas o resultado vale a pena!

```
# Gerar gráfico
juros_real %>%
  ggplot(aes(x = data, y = valor, colour = id)) +
  geom_hline(yintercept = 0, size = .8, color = "gray50") +
  geom_line(size = 1.8) + 
  geom_label_repel(
    data        = subset(juros_real, data == max(data)),
    aes(label   = paste(scales::comma(valor, decimal.mark = ",", accuracy = 0.01))),
    show.legend = FALSE,
    nudge_x     = 50,
    nudge_y     = 7,
    force       = 10,
    size        = 5,
    fontface = "bold"
    ) +
  labs(
    title    = "Taxa de juros real - Brasil",
    subtitle = paste0("Taxa mensal (em % a.a.), dados até ", format(tail(juros_real$data, 1), "%b/%Y")),
    x        = "",
    y        = NULL,
    caption  = "Fonte: B3, BCB e IBGE"
    ) +
  scale_color_manual(values = c("#233f91", "red4")) +
  scale_x_date(breaks = "2 years", date_labels = "%Y") +
  scale_y_continuous(labels = scales::label_percent(scale = 1, accuracy = 1)) +
  theme_minimal() +
  theme(
    plot.title         = element_text(color = "#233f91", size = 26, face = "bold"),
    plot.subtitle      = element_text(face = "bold", colour = "gray20", size = 16),
    plot.background    = element_rect(fill = "#eef1f7", colour = "#eef1f7"),
    plot.caption       = element_text(size = 10, face = "bold", colour = "gray20"),
    legend.background  = element_blank(),
    legend.position    = c(0.9, 0.72),
    legend.title       = element_blank(),
    legend.text        = element_text(face = "bold", colour = "gray20", size = 16),
    panel.background   = element_rect(fill = "#eef1f7", colour = "#eef1f7"),
    panel.grid         = element_line(colour = "gray85"),
    panel.grid.minor.x = element_blank(),
    axis.text          = element_text(size = 13, face = "bold")
    )
```

{{< vs 2>}}
Voilà! Eis o gráfico mostrado acima com os resultados do cálculo de juros real pelos conceitos ex-ante e ex-post. Espero que esse conteúdo tenha sido útil ou interessante para você. Até mais!

{{< vs 2>}}
<script type="text/javascript" src="https://cdnjs.buymeacoffee.com/1.0.0/button.prod.min.js" data-name="bmc-button" data-slug="schoulten" data-color="#40DCA5" data-emoji=""  data-font="Cookie" data-text="Buy me a coffee" data-outline-color="#000000" data-font-color="#ffffff" data-coffee-color="#FFDD00" ></script>
