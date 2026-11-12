# =============================================================================
# 01c_download_datasus.R — Saúde/MORTALIDADE via microdatasus  [ALTERNATIVA OPCIONAL]
# -----------------------------------------------------------------------------
# CAMINHO CANÔNICO DA SAÚDE = TABNET para tudo (casos E óbitos), em 04b_saude.R,
# espelhando o Monitor SP (compilação manual do TABNET). Como os CASOS notificados
# (TB/hepatite/HIV) só existem via TABNET (microdatasus não cobre esses SINAN), optou-se
# por fazer TAMBÉM a mortalidade pelo TABNET, unificando o fluxo e evitando a dependência
# do microdatasus (install_github, read.dbc no Windows, FTP instável).
# ESTE script fica como ALTERNATIVA OPCIONAL para quem preferir automatizar a mortalidade.
#
# O Panorama de Saúde do Monitor SP traz, por município e ano: (a) CASOS NOTIFICADOS
# e (b) MORTES por tuberculose, hepatite e HIV (Notas Metodológicas de SP).
#
# DIVISÃO DE FONTES (confirmada na doc do microdatasus, rfsaldanha.github.io/microdatasus):
#   - MORTALIDADE  -> SIM-DO via microdatasus  (ESTE script). Totalmente scriptável.
#   - CASOS notificados (TB/hepatite/HIV) -> microdatasus NÃO cobre esses SINAN
#     (só dengue/chikungunya/zika/malária/chagas/leishmaniose/leptospirose). Esses
#     vêm de exportação TABNET (como SP faz) e são tratados em 04b_saude_casos.R.
#
# Indicadores de mortalidade (causa básica, CID-10):
#   - Tuberculose      : A15–A19
#   - Hepatites virais : B15–B19
#   - Doença pelo HIV  : B20–B24
# Agregação: óbitos por município de residência (CODMUNRES) × ano (DTOBITO).
#
# Saída    : data/processed/saude_mortalidade_rs_municipio_ano.csv
# Auditoria: outputs/auditoria/saude_mortalidade_cobertura.csv
#
# Uso (no R do usuário, com internet):  source("scripts/rs/01c_download_datasus.R")
# Requer: microdatasus (remotes::install_github("rfsaldanha/microdatasus")) e, no
# Windows, o pacote read.dbc. Travar versão no renv.lock.
# =============================================================================

source(here::here("scripts/rs/00_config.R"))

if (!requireNamespace("microdatasus", quietly = TRUE))
  stop("Pacote 'microdatasus' ausente. Instale: remotes::install_github(\"rfsaldanha/microdatasus\").")

dir_out <- paths$processed

# Faixas de CID-10 (3 primeiros caracteres da causa básica) por grupo de doença
cid3 <- function(prefixos) prefixos
grupos_cid <- list(
  tuberculose    = sprintf("A%02d", 15:19),
  hepatite_viral = sprintf("B%02d", 15:19),
  hiv            = sprintf("B%02d", 20:24)
)
classifica_cid <- function(causabas) {
  p3 <- toupper(substr(causabas, 1, 3))
  dplyr::case_when(
    p3 %in% grupos_cid$tuberculose    ~ "tuberculose",
    p3 %in% grupos_cid$hepatite_viral ~ "hepatite_viral",
    p3 %in% grupos_cid$hiv            ~ "hiv",
    TRUE ~ NA_character_
  )
}

# Baixa e processa SIM-DO ano a ano (robusto a anos ainda não publicados; SIM tem defasagem).
baixar_obitos_ano <- function(ano) {
  tryCatch({
    d <- microdatasus::fetch_datasus(year_start = ano, year_end = ano,
                                     uf = cfg$uf, information_system = "SIM-DO")
    d <- microdatasus::process_sim(d, municipality_data = FALSE)
    d |>
      dplyr::mutate(doenca = classifica_cid(.data[["CAUSABAS"]]),
                    ano = ano,
                    cod_mun6 = substr(as.character(.data[["CODMUNRES"]]), 1, 6)) |>
      dplyr::filter(!is.na(doenca)) |>
      dplyr::count(cod_mun6, ano, doenca, name = "obitos")
  }, error = function(e) { message("⚠ SIM ", ano, " indisponível/erro: ", conditionMessage(e)); NULL })
}

obitos <- purrr::map_dfr(cfg$saude_anos, function(a) { message("SIM-DO ", a, " ..."); baixar_obitos_ano(a) })

if (nrow(obitos) == 0) stop("Nenhum óbito recuperado — verificar microdatasus/conexão.")

# formato largo: uma coluna por doença + total
saude_mort <- obitos |>
  tidyr::pivot_wider(names_from = doenca, values_from = obitos,
                     names_prefix = "obitos_", values_fill = 0) |>
  dplyr::mutate(obitos_doencas_total = rowSums(dplyr::across(dplyr::starts_with("obitos_")))) |>
  dplyr::arrange(cod_mun6, ano)

readr::write_csv(saude_mort, file.path(dir_out, "saude_mortalidade_rs_municipio_ano.csv"))

# ---- Auditoria ---------------------------------------------------------------
auditoria <- obitos |>
  dplyr::group_by(ano) |>
  dplyr::summarise(municipios = dplyr::n_distinct(cod_mun6),
                   obitos_total = sum(obitos), .groups = "drop")
readr::write_csv(auditoria, file.path(paths$out_aud, "saude_mortalidade_cobertura.csv"))

message("OK — saude_mortalidade_rs_municipio_ano.csv (", nrow(saude_mort), " linhas) e auditoria gravados.")
print(auditoria)

# NOTA: o código IBGE do SIM é de 6 dígitos (CODMUNRES). A junção ao painel (id_municipio
# de 7 dígitos) é feita por substr(id_municipio, 1, 6) no 04/05.
