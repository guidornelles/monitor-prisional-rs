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

readr::write_csv(contexto, file.path(paths$processed, "contexto_rs_municipio.csv"))

# ---- 6) Auditoria de cobertura -----------------------------------------------
auditoria <- tibble::tibble(
  metrica = c("municipios", "regioes_intermediarias", "sem_populacao",
              "sem_pib", "sem_distorcao"),
  valor = c(nrow(contexto),
            dplyr::n_distinct(contexto$nome_regiao_intermediaria),
            sum(is.na(contexto$populacao)),
            sum(is.na(contexto$pib)),
            sum(is.na(contexto$distorcao_idade_serie_fund)))
)
readr::write_csv(auditoria, file.path(paths$out_aud, "contexto_cobertura.csv"))

message("OK — contexto_rs_municipio.csv (", nrow(contexto), " municípios, ",
        dplyr::n_distinct(contexto$nome_regiao_intermediaria), " regiões) e auditoria gravados.")
print(auditoria)
