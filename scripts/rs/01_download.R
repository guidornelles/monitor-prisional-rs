# =============================================================================
# 01_download.R — Aquisição reprodutível dos dados NACIONAIS (contexto)
# -----------------------------------------------------------------------------
# Fontes nacionais usadas pelo Monitor SP (conforme as Notas Metodológicas):
#   - População municipal (IBGE)            -> denominador das taxas + Panorama Populacional
#   - Região geográfica intermediária (IBGE)-> recorte regional (mesmo conceito de SP)
#   - PIB municipal (IBGE)                  -> Panorama Econômico
#   - Distorção idade-série (INEP)          -> Panorama Educacional
#   - Saúde TB/hepatite/HIV/mortalidade (DATASUS) -> Panorama de Saúde  [módulo 01c, opcional]
#
# Estratégia de reprodutibilidade: usar PACOTES R que encapsulam as APIs oficiais
# (sidrar/IBGE, geobr, microdatasus) em vez de URLs de portal (frágeis). As versões
# dos pacotes ficam travadas no renv.lock. Saídas brutas em data/raw/nacional/.
#
# Uso (no R do usuário, com internet):  source("scripts/rs/01_download.R")
# =============================================================================

source(here::here("scripts/rs/00_config.R"))

dir_nac <- here::here("data/raw/nacional"); dir.create(dir_nac, recursive = TRUE, showWarnings = FALSE)
COD_UF_RS <- 43   # código IBGE da UF do Rio Grande do Sul

`%||%` <- function(a, b) if (is.null(a)) b else a

# Pacotes específicos de aquisição (instalar via renv): sidrar, jsonlite, readr.
need <- c("sidrar", "jsonlite")
faltando <- need[!vapply(need, requireNamespace, logical(1), quietly = TRUE)]
if (length(faltando)) message("⚠ Pacotes ausentes (instalar via renv): ", paste(faltando, collapse = ", "))

# ---- 1) Região geográfica intermediária do IBGE (município -> região) --------
# SP usa as REGIÕES GEOGRÁFICAS INTERMEDIÁRIAS do IBGE (coluna nome_regiao_intermediaria).
# O geobr simplificado só traz a MACRORregião ("Sul"); por isso usamos a API oficial de
# localidades do IBGE (view=nivelado), que devolve o vínculo município->região intermediária.
# Auto-validação: RS tem 497 municípios e 8 regiões intermediárias (erro alto se não bater).
baixar_regioes <- function() {
  url <- sprintf("https://servicodados.ibge.gov.br/api/v1/localidades/estados/%d/municipios?view=nivelado", COD_UF_RS)
  d <- jsonlite::fromJSON(url)
  nm <- names(d)
  ci <- function(pat) { hit <- nm[grepl(pat, nm, ignore.case = TRUE)]; if (length(hit)) hit[1] else NA_character_ }
  col_id  <- ci("municipio[-_.]?id$")
  col_nom <- ci("municipio[-_.]?nome$")
  col_ri  <- ci("intermediaria[-_.]?nome$")
  col_uf  <- ci("^UF[-_.]?sigla$|UF[-_.]?sigla$")
  if (any(is.na(c(col_id, col_nom, col_ri))))
    stop("Colunas da API IBGE não reconhecidas (id/nome/intermediária). Disponíveis: ", paste(nm, collapse = ", "))
  muni <- tibble::tibble(
    id_municipio = suppressWarnings(as.integer(d[[col_id]])),
    nome = d[[col_nom]],
    nome_regiao_intermediaria = d[[col_ri]],
    sigla_uf = if (!is.na(col_uf)) d[[col_uf]] else "RS"
  ) |>
    dplyr::filter(!is.na(id_municipio), !is.na(nome_regiao_intermediaria))   # remove registro vazio espúrio da API
  if (nrow(muni) < 490 || dplyr::n_distinct(muni$nome_regiao_intermediaria) != 8)
    stop("Validação falhou: ", nrow(muni), " municípios / ",
         dplyr::n_distinct(muni$nome_regiao_intermediaria),
         " regiões intermediárias (esperado ~497 / 8). Conferir a resposta da API.")
  readr::write_csv(muni, file.path(dir_nac, "ibge_municipios_regioes_rs.csv"))
  message("OK região intermediária RS: ", nrow(muni), " municípios, ",
          dplyr::n_distinct(muni$nome_regiao_intermediaria), " regiões -> ibge_municipios_regioes_rs.csv")
  invisible(muni)
}

# ---- 2) População municipal (IBGE/SIDRA) -------------------------------------
# Denominador das taxas por 100 mil. PoC: população do Censo 2022 (tabela 4709) por
# município do RS; estimativas anuais podem refinar depois (ver decisões §taxas).
baixar_populacao <- function() {
  # SIDRA t.4709 = População residente (Censo 2022). /n6/in n3 43 = municípios do RS.
  pop <- sidrar::get_sidra(x = 4709, variable = 93,
                           geo = "City", geo.filter = list("State" = COD_UF_RS))
  readr::write_csv(pop, file.path(dir_nac, "ibge_populacao_municipios_rs_2022.csv"))
  message("OK população (Censo 2022) RS -> ibge_populacao_municipios_rs_2022.csv")
  invisible(pop)
}

# ---- 3) PIB municipal (IBGE/SIDRA) -------------------------------------------
baixar_pib <- function() {
  # SIDRA t.5938 = PIB dos municípios (último ano disponível). Filtra RS.
  pib <- sidrar::get_sidra(x = 5938, variable = 37,
                           geo = "City", geo.filter = list("State" = COD_UF_RS))
  readr::write_csv(pib, file.path(dir_nac, "ibge_pib_municipios_rs.csv"))
  message("OK PIB municipal RS -> ibge_pib_municipios_rs.csv")
  invisible(pib)
}

# ---- 4) Distorção idade-série (INEP) -----------------------------------------
# Taxa de distorção idade-série por MUNICÍPIO (Ensino Fundamental é o recorte de SP).
# INEP publica em ZIP por ano, com padrão de URL estável:
#   .../indicadores_educacionais/<ano>/TDI_<ano>_MUNICIPIOS.zip
ANO_INEP <- 2024   # ano da divulgação (SP usou 2024); parametrizável
url_inep_distorcao <- function(ano) sprintf(
  "https://download.inep.gov.br/informacoes_estatisticas/indicadores_educacionais/%d/TDI_%d_MUNICIPIOS.zip",
  ano, ano)
baixar_distorcao <- function() {
  dest_zip <- file.path(dir_nac, sprintf("inep_tdi_%d_municipios.zip", ANO_INEP))
  if (!file.exists(dest_zip) || file.info(dest_zip)$size == 0)
    utils::download.file(url_inep_distorcao(ANO_INEP), dest_zip, mode = "wb", quiet = TRUE)
  exdir <- file.path(dir_nac, "inep_distorcao"); dir.create(exdir, showWarnings = FALSE)
  utils::unzip(dest_zip, exdir = exdir, overwrite = TRUE)
  message("OK distorção idade-série (município, ", ANO_INEP, ") -> ", basename(dest_zip))
}

# ---- Execução ----------------------------------------------------------------
# Cada bloco é protegido: uma fonte que falhe não derruba as demais (o erro é
# reportado e o download manual fica documentado).
res <- list()
for (nm in c("baixar_regioes","baixar_populacao","baixar_pib","baixar_distorcao")) {
  res[[nm]] <- tryCatch({ get(nm)(); "ok" },
    error = function(e) { message("⚠ ", nm, " falhou: ", conditionMessage(e)); "erro" })
}
message("\nResumo 01_download: ", paste(names(res), unlist(res), sep="=", collapse=" | "))
message("Saúde (DATASUS) é tratada em 01c_download_datasus.R (opcional; ver Notas de SP).")
