---
title: "O que os cofres municipais revelam sobre a gestão fiscal das prefeituras?"
date: 2021-02-23
description: Um índice para mensurar a gestão fiscal dos municípios, adaptado da metodologia da Firjan
menu:
  sidebar:
    name: Índice de Gestão Fiscal Municipal - IGFM
    identifier: igfm
    parent: financas-publicas
    weight: 10
---

### Introdução

5.570 novos prefeitos foram eleitos na última eleição municipal do Brasil, em um contexto e campanha ainda dominamos pela pandemia da Covid-19, e tomaram posse em 1º de janeiro de 2021 com muitos velhos desafios. Com o que se depararam nas prefeituras?

É bem sabido que nosso país passa por um momento crítico em suas contas públicas. Estamos há quase 6 anos registrando consecutivos déficits primários - quando as despesas primárias superam a receita primária líquida -, período no qual a trajetória da dívida pública federal cresceu explosivamente e estados e municípios declararam insolvência. No contexto municipal, observa-se que muitas prefeituras possuem pouca capacidade de gerar receita para financiar até mesmo sua estrutura administrativa, constituindo-se um desafio vital para a gestão fiscal dos municípios brasileiros.

Mas como identificar se um município possui uma situação fiscal boa ou crítica? Em outras palavras, como podemos mensurar e visualizar essa realidade brasileira?


### Índice de Gestão Fiscal Municipal – IGFM

Para visualizar a gravidade desse problema, desenvolvi o **Índice de Gestão Fiscal Municipal – IGFM**, que mede a capacidade dos municípios brasileiros se sustentarem em um intervalo de 0 a 1. O índice é uma adaptação da metodologia da [Firjan](https://www.firjan.com.br/ifgf/) e os dados são públicos e disponibilizados no sistema [Siconfi/STN](https://siconfi.tesouro.gov.br/) referentes às Contas Anuais de 2018.

São consideradas no cálculo do índice as receitas provenientes da atividade econômica municipal e as despesas para manter a Câmara de Vereadores e a estrutura administrativa da Prefeitura, de forma que quanto mais próximo de zero estiver o IGFM do município menor é a capacidade do mesmo gerar receitas e arcar com os custos de sua própria existência.


### O triste mapa da gestão fiscal dos municípios

No mapa abaixo constam os resultados do IGFM categorizados em 4 níveis de situação: crítica, difícil, boa e excelente. Podemos observar que 2.415 prefeituras (44,4% do total) estão em situação crítica e difícil, ou seja, não conseguem gerar receita suficiente para custear a própria estrutura administrativa. A maior parcela desse número é composta por municípios pequenos, concentrados nas regiões Norte e Nordeste, nos quais a população média não passa de 14 mil pessoas.

{{< img src="/posts/financas-publicas/igfm/img/igfm.jpg" align="center" width="450" >}}

Esse resultado evidencia uma grande ineficiência na administração dos recursos públicos. Nesse contexto, propostas de reforma administrativa vêm sendo debatidas e indicadores como esses são importantes para entender o problema. É fundamental discutir e propor soluções para fatores como esse, caso contrário este mapa mostrará um Brasil cada vez mais crítico.


### Dados, cálculos e código

Como chegar a esses resultados do índice? Como mencionado, a Firjan disponibiliza metodologia própria para o cálculo do índice, que é muito semelhante ao desenvolvido aqui. Abaixo irei detalhar os procedimentos adotados a partir de uma interpretação livre da metodologia da Firjan. Importante frisar que os resultados obtidos podem divergir daqueles que a Firjan disponibiliza em virtude de arredondamentos ou diferenças de cálculo (que não é explicitamente claro na documentação técnica disponibilizada).

Vamos usar a linguagem R com o auxílio de alguns pacotes para obter e tratar dados, assim como para a criação do mapa municipal.

{{< vs 2>}}
#### 1. Carregar pacotes necessários

Para fins de reprodutibilidade, usaremos o {pacman} - que é um gerenciador de pacotes - para verificar se os pacotes estão instalados e instalar/carregar caso necessário; o {rsiconfi} é um pacote em desenvolvimento que utilizaremos para obter dados do Siconfi/STN via API; {brazilmaps} e {sf} são pacotes gráficos que serão utilizados para gerar o mapa; e, por último, o {tidyverse} é uma família de pacotes para manipulação de dados.

```
# Instalar/carregar pacotes
if (!require("pacman")) install.packages("pacman")
if (!require("rsiconfi")) devtools::install_github("tchiluanda/rsiconfi")
pacman::p_load("rsiconfi", "tidyverse", "brazilmaps", "sf")
```

{{< vs 2>}}
#### 2. Definir parâmetros para obtenção dos dados

Agora vamos criar alguns objetos que servirão como parâmetros para extrair os dados do sistema Siconfi. Esses parâmetros seriam os mesmos que preencheríamos se fossemos baixar manualmente um CSV dos dados pelo site.

```
# Ano de referência das Contas Anuais
ano <- 2018

# Anexo das Contas Anuais
anexo_receita <- "I-C"
anexo_despesa <- "I-E"

# Vetor com código IBGE das UFs do Brasil
uf_codigos <- c(
  11:17,
  21:29,
  31:35,
  41:43,
  50:53
  )

# Vetor com tipos de despesas que queremos filtrar
contas_despesas <- c(
  "01", # Legislativa
  "02", # Judiciária
  "03", # Essencial à Justiça
  "04"  # Administração
  )

# Vetor com tipos de receitas que queremos filtrar
contas_receitas <- c(
  "1.0.0.0.00.0.0",     # Receitas Correntes,
  "1.7.0.0.00.0.0",     # Transferências Correntes,
  "1.1.1.0.00.0.0",     # Impostos
  "1.3.0.0.00.0.0",     # Receita Patrimonial
  "1.4.0.0.00.0.0",     # Receita Agropecuária
  "1.5.0.0.00.0.0",     # Receita Industrial
  "1.6.0.0.00.0.0",     # Receita de Serviços
  "1.7.1.8.01.5.0",     # Cota-Parte do Imposto Sobre a Propriedade Territorial Rural
  "1.7.1.8.06.0.0",     # Transferência Financeira do ICMS – Desoneração – L.C. Nº 87/96
  "1.7.2.8.01.1.0",     # Cota-Parte do ICMS
  "1.7.2.8.01.2.0",     # Cota-Parte do IPVA
  "1.7.2.8.01.3.0",     # Cota-Parte do IPI - Municípios
  "RO1.7.2.8.01.1.0",   # Cota-parte do ICMS,
  "RO1.7.2.8.01.2.0",   # Cota-parte do IPVA,
  "RO1.7.1.8.01.5.0",   # Cota-parte do ITR,
  "1.7.2.8.01.3.0 Cota-Parte do IPI"
  )

```

{{< vs 2>}}
#### 3. Coletar dados usando o {rsiconfi}

Definidos os parâmetros, podemos usar a função `get_dca_mun_state()` para baixar os dados (via API).

{{< alert type="warning" >}}
**Importante:** A extração de dados pode ser demorada, podendo levar horas! Caso deseje, disponibilizei os dados aqui utilizados referentes à 2018 no meu [GitHub](https://github.com/schoulten/indice-igfm/blob/main/data/fiscal_mun.Rdata).
{{< /alert >}}


```
# Coletar receitas orçamentárias municipais
tbl_receitas <- get_dca_mun_state(
  year          = ano,
  annex         = anexo_receita,
  state         = uf_codigos,
  arg_cod_conta = contas_receitas
  )

# Coletar despesas por função municipais
tbl_despesas <- get_dca_mun_state(
  year          = ano,
  annex         = anexo_despesa,
  state         = uf_codigos,
  arg_cod_conta = contas_despesas
  )

```

{{< vs 2>}}
#### 4. Tratamento de dados

Prosseguimos com o tratamento dos dados obtidos para posterior cálculo do índice. Nesta etapa, consideraremos somente o estágio de despesas líquidas e das receitas são deduzidos os percentuais destinados à formação do Fundeb. Além disso, calculamos a receita econômica local

```
# Receitas: deduzir Fundeb, totalizar contas por municípios e calcular receita econômica
receitas <- tbl_receitas %>%
  mutate(
    valor = ifelse(
      coluna == "Receitas Brutas Realizadas",
      valor,
      -valor # dedução de valores destinados ao Fundeb
      )
    ) %>%
  group_by(cod_ibge, cod_conta) %>%
  summarise(valor_liquido = sum(valor)) %>%
  pivot_wider(
    id_cols     = cod_ibge, 
    names_from  = cod_conta, 
    values_from = valor_liquido
    ) %>%
  ungroup() %>%
  mutate( # Receitas Correntes - Transferências Correntes + Receitas + Cotas e Transferências
    rec_econ = RO1.0.0.0.00.0.0 - RO1.7.0.0.00.0.0 + rowSums(.[c(3:5,7:12)], na.rm = TRUE)
    ) %>%
  select(1,2,13) %>%
  rename_with(
    ~c("rec_corr_liq"),
    2
    ) %>%
  mutate(
    rec_corr_liq = ifelse(rec_corr_liq < 1, 0, rec_corr_liq), # tratar receitas menores que 1 como sendo 0
    rec_econ     = ifelse(rec_econ < 1, 0, rec_econ) # tratar receitas menores que 1 como sendo 0
    )

# Despesas: filtrar e selecionar colunas relevantes, pivotar e renomear colunas
despesas <- tbl_despesas %>%
  filter(coluna == "Despesas Liquidadas") %>%
  select(cod_ibge, conta, valor) %>%
  pivot_wider(
    id_cols     = cod_ibge, 
    names_from  = conta, 
    values_from = valor
    ) %>%
  rename_with(
    ~c("legislativa",
      "administracao", 
      "essencial_a_justica",
      "judiciaria"
      ),
    2:5
    )
```

{{< vs 2>}}
#### 5. Calcular o índice

O próximo passo é efetivamente calcular o índice que avalia se as receitas são suficientes para cobrir as despesas com a estrutura administrativa municipal. Para tal, fazemos a união dos dois conjuntos de dados baixados e tratados, substituímos os valores ausentes por zero e criamos o índice seguindo a fórmula abaixo:

**IGFM** = (Receitas de Atividade Econômica - Despesas com Estrutura Administrativa) / Receita Corrente Líquida

Adicionalmente, fazemos uma tratativa para casos em que a receita de atividade econômica é zero, transformamos os valores de acordo com a metodologia da Firjan de valores maiores que 0,25 = 1, entre 0 e 0,25 dividimos por 0,25 e demais casos (e.g.negativos) são transformados em 0. Criamos 4 categorias com fins de suavizar e padronizar os resultados na visualização dos mesmos:

  1. **Excelente**: índice maior que 0,8
  2. **Boa**: índice entre 0,6 e 0,8
  3. **Difícil**: índice entre 0,4 e 0,6
  4. **Crítica**: índice menor que 0,4

```
# Calcular o IGFM
tbl_igfm <- despesas %>%
  inner_join(receitas) %>%
  replace(is.na(.), 0) %>%
  mutate(
    indicador      = (rec_econ - legislativa - administracao - essencial_a_justica - judiciaria) / rec_corr_liq,
    indicador      = ifelse(rec_econ == 0, 0, indicador),
    igfm_autonomia =  case_when(
      indicador > 0.25 ~ 1,
      indicador < 0.25 & indicador > 0 ~ indicador/0.25,
      TRUE ~ 0
      ),
    categoria      = case_when(
      igfm_autonomia > 0.8 ~ "Excelente",
      igfm_autonomia > 0.6 & igfm_autonomia < 0.8 ~ "Boa",
      igfm_autonomia > 0.4 & igfm_autonomia < 0.6 ~ "Difícil",
      igfm_autonomia < 0.4 ~ "Crítica"
      ) %>% factor(levels = c("Excelente", "Boa", "Difícil", "Crítica"))
    )
```

{{< vs 2>}}
#### 6. Criar o mapa

A parte mais legal é essa, por isso ficou por último :D!

Para gerar a visualização desejada primeiro precisamos baixar os parâmetros (polígonos espaciais) que darão a cara pro nosso mapa, e isso é feito com a função `get_brmap()`. Após isso, juntos esses dados com os dados do índice que calculamos e usamos o pacote {ggplot2} para plotar todos esses dados.

```
# Gerar mapa
get_brmap("City") %>%
  inner_join(tbl_igfm, c("City" = "cod_ibge")) %>% 
  ggplot() +
  geom_sf(aes(fill = categoria), color = NA, size = 0.15)  +
  geom_sf(data = get_brmap("State"), fill = "transparent", colour = "black", size = 0.5) +
  labs(
    title    = "Índice de Gestão Fiscal Municipal - IGFM",
    subtitle = "Dados de 2018, metodologia adaptada da Firjan",
    caption  = "Fonte: Fernando da Silva com dados de Siconfi/STN"
    ) +
  scale_fill_brewer(palette = "Spectral", name = "Situação:", direction = -1) +
  theme(
    axis.text          = element_blank(),
    axis.ticks         = element_blank(),
    plot.title         = element_text(color = "#233f91", size = 15, face = "bold"),
    plot.subtitle      = element_text(face = "bold", colour = "gray20", size = 12),
    plot.caption       = element_text(size = 10, face = "bold", colour = "gray20"),
    legend.position    = c(0.15,0.2),
    legend.title       = element_text(face = "bold", colour = "gray20", size = 12),
    legend.background  = element_blank(),
    legend.text        = element_text(face = "bold", colour = "gray20", size = 12),
    panel.grid         = element_line(colour = "transparent"),
    panel.background   = element_rect(fill = "#eef1f7", colour = "#eef1f7"),
    plot.background    = element_rect(fill = "#eef1f7", colour = "#eef1f7")
    )
```

{{< vs 2>}}
Voilà! Eis o mapa com os resultados do índice. Espero que esse conteúdo tenha sido útil ou interessante para você. Até mais!

Aviso: esse post é uma atualização do [texto publicado](https://github.com/schoulten/indice-igfm) originalmente para o GECE/FURG.

{{< vs 2>}}
<script type="text/javascript" src="https://cdnjs.buymeacoffee.com/1.0.0/button.prod.min.js" data-name="bmc-button" data-slug="schoulten" data-color="#40DCA5" data-emoji=""  data-font="Cookie" data-text="Buy me a coffee" data-outline-color="#000000" data-font-color="#ffffff" data-coffee-color="#FFDD00" ></script>
