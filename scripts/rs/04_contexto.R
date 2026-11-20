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
# Os panoramas históricos têm tabela própria, preparada por
# scripts/exploratory/preparar_panoramas_historicos_rs.py.
# =============================================================================

source(here::here("scripts/rs/00_config.R"))
source(here::here("R/funcoes_contexto.R"))
dir_nac <- here::here("data/raw/nacional")

# ---- 1) Município -> região geográfica intermediária -------------------------
regioes <- readr::read_csv(file.path(dir_nac, "ibge_municipios_regioes_rs.csv"),
                           show_col_types = FALSE) |>
  dplyr::transmute(id_municipio = as.integer(id_municipio),
                   nome, nome_regiao_intermediaria) |>
  dplyr::filter(!is.na(id_municipio))   # descarta registro vazio espúrio (caso o 01 antigo o tenha deixado)

# ---- 2) População (Censo 2022 — denominador das taxas) -----------------------
# SIDRA t.4709: o ano e a unidade devem corresponder ao denominador fixado.
arq_pop <- file.path(dir_nac, "ibge_populacao_municipios_rs_2022.csv")
pop <- contexto_ler_sidra(arq_pop, cfg$contexto$ano_populacao, 93, "Pessoas", "populacao")
if (any(pop$populacao <= 0)) stop("População municipal deve ser positiva para calcular taxas.")

# ---- 3) PIB municipal --------------------------------------------------------
arq_pib <- file.path(dir_nac, "ibge_pib_municipios_rs.csv")
pib <- contexto_ler_sidra(arq_pib, cfg$contexto$ano_pib, 37, "Mil Reais", "pib")

# ---- 4) Distorção idade-série (INEP, Ensino Fundamental, total do município) --
# Cabeçalho-máquina do TDI está na 9ª linha (skip = 8). Recorte: Localização=Total e
# Dependência=Total -> valor agregado municipal; coluna FUN_CAT_0 = Ens. Fundamental.
arq_tdi <- contexto_arquivo_tdi(file.path(dir_nac, "inep_distorcao"), cfg$contexto$ano_tdi,
                               cfg$inep_tdi_xlsx_md5)
distorcao <- contexto_ler_tdi(arq_tdi, cfg$contexto$ano_tdi, cfg$uf)
contexto_validar_chaves(regioes, n = cfg$n_municipios, fonte = "Cadastro IBGE")
for (camada in c("pop", "pib", "distorcao"))
  contexto_validar_chaves(get(camada), ids = regioes$id_municipio, fonte = camada)

# ---- 5) Junção (base = municípios/regiões) -----------------------------------
contexto <- regioes |>
  dplyr::left_join(pop,       by = "id_municipio") |>
  dplyr::left_join(pib,       by = "id_municipio") |>
  dplyr::left_join(distorcao, by = "id_municipio") |>
  dplyr::arrange(nome)

# ---- 5b) munic_ep: o município TEM estabelecimento penal? (SISDEPEN, recorte da PoC) ----
# SP carrega essa flag (munic_ep_*) na base de contexto do DataStudio (e tem_EP/Tem_prisão
# nas camadas criminal/saúde). É presença em pelo menos um dos ciclos da janela
# prisional, não um retrato atual ou uma série anual de abertura/fechamento.
# Depende do 03 (roda antes do 04 no run_all). Alimenta o export formato-SP (05b).
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

# Referência e hash das entradas efetivamente usadas, sem depender da ordem da pasta.
fontes <- tibble::tibble(
  fonte = c("IBGE Censo", "IBGE PIB municipal", "Inep TDI ensino fundamental Total/Total"),
  ano = c(cfg$contexto$ano_populacao, cfg$contexto$ano_pib, cfg$contexto$ano_tdi),
  unidade = c("Pessoas", "Mil Reais correntes", "Percentual de matrículas"),
  arquivo = normalizePath(c(arq_pop, arq_pib, arq_tdi), winslash = "/"),
  md5 = unname(tools::md5sum(c(arq_pop, arq_pib, arq_tdi))))
readr::write_csv(fontes, file.path(paths$out_aud, "contexto_fontes.csv"))
