# =============================================================================
# 04_contexto.R — Camada de CONTEXTO (denominadores e panoramas), padrão SP
# -----------------------------------------------------------------------------
# Monta a tabela municipal de contexto que alimenta as taxas por 100 mil e os
# "panoramas" do Monitor (populacional, econômico, educacional). Espelha os nomes
# de variável usados por SP (populacao_municipios_sp.xlsx / pib_municipios_sp.xlsx):
#   id_municipio, nome, nome_regiao_intermediaria, populacao, pib, distorcao_idade_serie_fund
#
# Entradas (baixadas por 01_download.R, em data/raw/nacional/):
#   - ibge_municipios_regioes_rs.csv          (API IBGE: município -> região intermediária)
#   - ibge_populacao_municipios_rs_2022.csv   (SIDRA 4709: população Censo 2022 — denominador)
#   - ibge_pib_municipios_rs.csv              (SIDRA 5938: PIB municipal)
#   - inep_distorcao/.../TDI_MUNICIPIOS_*.xlsx(INEP: distorção idade-série, Ens. Fundamental)
# Saída    : data/processed/contexto_rs_municipio.csv
# Auditoria: outputs/auditoria/contexto_cobertura.csv
#
# NOTA: SP mantém população por vários censos (1991/2000/2010/2022) para o Panorama
# Populacional; aqui o denominador das taxas é o Censo 2022 (coluna `populacao`).
# Séries censitárias históricas podem ser anexadas depois (SIDRA tabelas históricas).
# =============================================================================

source(here::here("scripts/rs/00_config.R"))
dir_nac <- here::here("data/raw/nacional")

# ---- 1) Município -> região geográfica intermediária -------------------------
regioes <- readr::read_csv(file.path(dir_nac, "ibge_municipios_regioes_rs.csv"),
                           show_col_types = FALSE) |>
  dplyr::transmute(id_municipio = as.integer(id_municipio),
                   nome, nome_regiao_intermediaria) |>
  dplyr::filter(!is.na(id_municipio))   # descarta registro vazio espúrio (caso o 01 antigo o tenha deixado)

# ---- 2) População (Censo 2022 — denominador das taxas) -----------------------
# SIDRA t.4709: a coluna "Valor" é a população; "Município (Código)" é o id IBGE.
pop <- readr::read_csv(file.path(dir_nac, "ibge_populacao_municipios_rs_2022.csv"),
                       show_col_types = FALSE) |>
  dplyr::transmute(id_municipio = as.integer(`Município (Código)`),
                   populacao = readr::parse_number(as.character(Valor)))

# ---- 3) PIB municipal --------------------------------------------------------
pib <- readr::read_csv(file.path(dir_nac, "ibge_pib_municipios_rs.csv"),
                       show_col_types = FALSE) |>
  dplyr::transmute(id_municipio = as.integer(`Município (Código)`),
                   pib = readr::parse_number(as.character(Valor)))

# ---- 4) Distorção idade-série (INEP, Ensino Fundamental, total do município) --
# Cabeçalho-máquina do TDI está na 9ª linha (skip = 8). Recorte: Localização=Total e
# Dependência=Total -> valor agregado municipal; coluna FUN_CAT_0 = Ens. Fundamental.
arq_tdi <- list.files(file.path(dir_nac, "inep_distorcao"),
                      pattern = "TDI_MUNICIPIOS_.*\\.xlsx$", recursive = TRUE, full.names = TRUE)[1]
# suppressWarnings: o arquivo do INEP tem rodapé ("Fonte: Censo...") que dispara aviso de
# coerção numérica; é descartado pelo filtro RS+Total adiante (sem_distorcao=0 na auditoria).
distorcao <- suppressWarnings(readxl::read_excel(arq_tdi, skip = 8)) |>
  dplyr::filter(SG_UF == cfg$uf, NO_CATEGORIA == "Total", NO_DEPENDENCIA == "Total") |>
  dplyr::transmute(id_municipio = as.integer(CO_MUNICIPIO),
                   distorcao_idade_serie_fund = suppressWarnings(as.numeric(FUN_CAT_0)))  # "--" -> NA

# ---- 5) Junção (base = municípios/regiões) -----------------------------------
contexto <- regioes |>
  dplyr::left_join(pop,       by = "id_municipio") |>
  dplyr::left_join(pib,       by = "id_municipio") |>
  dplyr::left_join(distorcao, by = "id_municipio") |>
  dplyr::arrange(nome)

# ---- 5b) munic_ep: o município TEM estabelecimento penal? (SISDEPEN, recorte da PoC) ----
# SP carrega essa flag (munic_ep_*) na base de contexto do DataStudio (e tem_EP/Tem_prisão
# nas camadas criminal/saúde). Aqui é a presença ATUAL (não há série histórica de presídios):
# 1 se o município aparece na camada prisional (prisional_rs.csv, cela física), senão 0.
# Depende do 03 (roda antes do 04 no run_all). Alimenta também o export formato-SP (06).
arq_pris <- file.path(paths$processed, "prisional_rs.csv")
if (file.exists(arq_pris)) {
  pris <- readr::read_csv(arq_pris, show_col_types = FALSE)
  col_ibge <- intersect(c("Código IBGE", "Codigo IBGE", "cod_ibge"), names(pris))[1]
  if (!is.na(col_ibge)) {
    if (!"ano_inauguracao" %in% names(pris)) pris$ano_inauguracao <- NA_integer_
    # por município: tem EP? e o MENOR ano de inauguração (= tem_EP do criminal em SP)
    ep_mun <- pris |>
      dplyr::mutate(id_municipio = as.integer(.data[[col_ibge]])) |>
      dplyr::filter(!is.na(id_municipio)) |>
      dplyr::group_by(id_municipio) |>
      dplyr::summarise(ano_ep = suppressWarnings(min(ano_inauguracao, na.rm = TRUE)), .groups = "drop") |>
      dplyr::mutate(ano_ep = ifelse(is.finite(ano_ep), as.integer(ano_ep), NA_integer_))
    contexto <- contexto |>
      dplyr::mutate(munic_ep = as.integer(id_municipio %in% ep_mun$id_municipio)) |>
      dplyr::left_join(ep_mun, by = "id_municipio")
    message("  munic_ep: ", sum(contexto$munic_ep), " município(s) com EP; ",
            "ano_ep (menor inauguração) anexado a ", sum(!is.na(contexto$ano_ep)), ".")
  } else {
    message("⚠ código IBGE não encontrado em prisional_rs.csv — munic_ep/ano_ep = NA.")
    contexto$munic_ep <- NA_integer_; contexto$ano_ep <- NA_integer_
  }
} else {
  message("⚠ prisional_rs.csv ausente — munic_ep/ano_ep = NA (rode 03_prisional.R antes do 04).")
  contexto$munic_ep <- NA_integer_; contexto$ano_ep <- NA_integer_
}

readr::write_csv(contexto, file.path(paths$processed, "contexto_rs_municipio.csv"))

# ---- 6) Auditoria de cobertura -----------------------------------------------
auditoria <- tibble::tibble(
  metrica = c("municipios", "regioes_intermediarias", "sem_populacao",
              "sem_pib", "sem_distorcao", "munic_com_ep"),
  valor = c(nrow(contexto),
            dplyr::n_distinct(contexto$nome_regiao_intermediaria),
            sum(is.na(contexto$populacao)),
            sum(is.na(contexto$pib)),
            sum(is.na(contexto$distorcao_idade_serie_fund)),
            sum(contexto$munic_ep, na.rm = TRUE))
)
readr::write_csv(auditoria, file.path(paths$out_aud, "contexto_cobertura.csv"))

message("OK — contexto_rs_municipio.csv (", nrow(contexto), " municípios, ",
        dplyr::n_distinct(contexto$nome_regiao_intermediaria), " regiões) e auditoria gravados.")
print(auditoria)
