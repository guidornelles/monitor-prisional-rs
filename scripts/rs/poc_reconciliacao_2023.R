# =============================================================================
# Prova de Conceito — Reconciliação microdado x agregados oficiais (RS, 2023)
# Monitor Prisional RS — diagnóstico de viabilidade
#
# Objetivo: provar que os microdados de ocorrências (Dados Abertos Mensais da
# SSP-RS) reproduzem as tabelas oficiais agregadas (Indicadores Criminais e VCM),
# validando o microdado como BASE ÚNICA e flexível para construir os indicadores
# no padrão do Monitor SP.
#
# Escopo: reconciliação criminal (homicídio, latrocínio, furtos, roubos,
# veículos, estupro). Ano-teste: 2023.
#
# NOTA: este script foi escrito para o ambiente R do usuário. A lógica foi
# validada por um espelho em Python (R não executável no ambiente de geração).
# Resultados esperados (estadual): homicídio doloso -0,2%; furtos -0,1%;
# roubos -0,3%; veículos ~0%; latrocínio -2,4%; estupro +1,6% (ver docs/poc_reconciliacao.md).
# =============================================================================

library(tidyverse)
library(readxl)

base_dir <- "data/EstatisticasCriminaisRS"
micro_csv <- file.path(base_dir, "DadosAbertos/Mensais",
                       "SPJ_DADOS_ABERTOS_OCORRENCIAS_JAN_DEZ_2023_em 06.01.2025.csv")
ind_xlsx  <- file.path(base_dir, "IndicadoresCriminais",
                       "28094229-site-geral-e-munici-pios-ano-2023-atualizado-em-05-mar-2025-dados-cvli-atualizado-publicacao.xlsx")
vcm_xlsx  <- file.path(base_dir, "IndicadoresCriminais",
                       "15143232-site-violencia-contra-as-mulheres-2023-atualizado-em-05-janeiro-2026-publicacao.xlsx")

# ---- normalização de município: maiúsculas, sem acento, espaços colapsados ----
norm_mun <- function(x) {
  x %>% str_to_upper() %>%
    stringi::stri_trans_general("Latin-ASCII") %>%
    str_squish()
}
nao_municipio <- function(x) {
  x %in% c("", "TOTAL", "TOTAL RS", "RIO GRANDE DO SUL", "RS") |
    str_starts(x, "FONTE") | str_starts(x, "NOTA") | str_starts(x, "OBS")
}

# ---- 1. microdado (latin-1, separador ';') ----------------------------------
# Lê apenas as colunas necessárias. O arquivo tem ~807 mil linhas e 124 colunas.
micro <- read_delim(
  micro_csv, delim = ";", locale = locale(encoding = "latin1"),
  col_select = c("Tipo Enquadramento", "Tipo Fato", "Municipio Fato", "Quantidade Vítimas"),
  col_types = cols(.default = "c")
) %>%
  rename(enq = `Tipo Enquadramento`, tipo_fato = `Tipo Fato`,
         mun = `Municipio Fato`, qvit = `Quantidade Vítimas`) %>%
  filter(str_to_lower(str_trim(tipo_fato)) == "consumado") %>%   # tabelas oficiais = fato consumado
  mutate(
    enq  = norm_mun(enq),
    munN = norm_mun(mun),
    qvit = replace_na(as.integer(qvit), 0L)
  )

# ---- regras de classificação (validadas na reconciliação) -------------------
# Veículo é contabilizado À PARTE de roubos/furtos (dicionário SSP-RS).
# "OUTROS ROUBOS"/"OUTROS FURTOS" entram nos totais gerais (usar contains, não starts_with).
# Latrocínio = roubos "COM MORTE".
micro <- micro %>%
  mutate(
    is_roubo    = str_detect(enq, "ROUBO"),
    is_furto    = str_detect(enq, "FURTO"),
    is_morte    = str_detect(enq, "COM MORTE"),
    roubo_veic  = enq %in% c("ROUBO DE VEICULO", "ROUBO DE VEICULO COM LESOES"),
    furto_veic  = enq %in% c("FURTO DE VEICULO", "FURTO VEICULO AUTOMOTOR TRANSPORTE OUTRO ESTADO"),
    cls = case_when(
      enq == "HOMICIDIO DOLOSO"                      ~ "homicidio_doloso",
      enq %in% c("ESTUPRO", "ESTUPRO DE VULNERAVEL") ~ "estupro",
      is_roubo & is_morte                            ~ "latrocinio",
      roubo_veic & !is_morte                         ~ "roubo_veiculo",
      is_roubo & !roubo_veic & !is_morte             ~ "roubos",
      furto_veic                                     ~ "furto_veiculo",
      is_furto & !furto_veic                         ~ "furtos",
      TRUE                                           ~ "outro"
    )
  ) %>%
  filter(!nao_municipio(munN))

# Ocorrências (contagem de linhas) e vítimas (soma de Quantidade Vítimas)
oco <- micro %>% count(munN, cls) %>% pivot_wider(names_from = cls, values_from = n, values_fill = 0)
vit <- micro %>% group_by(munN, cls) %>% summarise(v = sum(qvit), .groups = "drop") %>%
  pivot_wider(names_from = cls, values_from = v, values_fill = 0)

recon <- tibble(mun = oco$munN) %>%
  mutate(
    rec_homic_oco   = oco$homicidio_doloso,
    rec_homic_vit   = vit$homicidio_doloso,
    rec_furtos      = oco$furtos,
    rec_furto_veic  = oco$furto_veiculo,
    rec_roubos      = oco$roubos,
    rec_roubo_veic  = oco$roubo_veiculo,
    rec_latroc      = oco$latrocinio,
    rec_estupro_vit = vit$estupro
  )

# ---- 2. Indicadores Criminais oficiais (cabeçalho na linha 7 / índice 6) -----
ind <- read_excel(ind_xlsx, sheet = "2023", skip = 6) %>%
  rename_with(str_squish) %>%
  mutate(mun = norm_mun(Municípios)) %>%
  filter(!nao_municipio(mun)) %>%
  mutate(across(c(`Homicídio Doloso`, `Total de vítimas de Homicidio Doloso`,
                  Furtos, `Furto de Veículo`, Roubos, `Roubo de Veículo`, Latrocínio),
                ~ replace_na(as.numeric(.), 0)))

# ---- 3. VCM estupro oficial (cabeçalho na linha 3 / índice 2) ----------------
ev <- read_excel(vcm_xlsx, sheet = "Estupro", skip = 2) %>%
  rename_with(str_squish) %>%
  mutate(mun = norm_mun(Município), Total = replace_na(as.numeric(Total), 0)) %>%
  filter(!nao_municipio(mun)) %>%
  select(mun, off_estupro = Total)

# ---- 4. comparação ----------------------------------------------------------
comp <- ind %>%
  select(mun, `Homicídio Doloso`, `Total de vítimas de Homicidio Doloso`,
         Furtos, `Furto de Veículo`, Roubos, `Roubo de Veículo`, Latrocínio) %>%
  full_join(ev, by = "mun") %>%
  full_join(recon, by = "mun") %>%
  mutate(across(everything(), ~ if (is.numeric(.)) replace_na(., 0) else .))

resumo <- tribble(
  ~indicador,               ~oficial,                                   ~reconstruido,
  "Homicídio Doloso (oco)", sum(comp$`Homicídio Doloso`),               sum(comp$rec_homic_oco),
  "Homicídio vítimas",      sum(comp$`Total de vítimas de Homicidio Doloso`), sum(comp$rec_homic_vit),
  "Latrocínio (oco)",       sum(comp$Latrocínio),                       sum(comp$rec_latroc),
  "Furtos (oco)",           sum(comp$Furtos),                           sum(comp$rec_furtos),
  "Furto de Veículo (oco)", sum(comp$`Furto de Veículo`),               sum(comp$rec_furto_veic),
  "Roubos (oco)",           sum(comp$Roubos),                           sum(comp$rec_roubos),
  "Roubo de Veículo (oco)", sum(comp$`Roubo de Veículo`),               sum(comp$rec_roubo_veic),
  "Estupro (vítimas)",      sum(comp$off_estupro),                      sum(comp$rec_estupro_vit)
) %>% mutate(delta_pct = round((reconstruido - oficial) / oficial * 100, 2))

print(resumo)

dir.create("outputs/tabelas", recursive = TRUE, showWarnings = FALSE)
write_csv(resumo, "outputs/tabelas/poc_reconciliacao_2023_resumo.csv")
write_csv(comp,   "outputs/tabelas/poc_reconciliacao_2023_municipios.csv")
