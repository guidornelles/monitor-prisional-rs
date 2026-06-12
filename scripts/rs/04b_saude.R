# =============================================================================
# 04b_saude.R — Panorama de Saúde (ingestão das exportações TABNET) por município×ano
# -----------------------------------------------------------------------------
# Lê os CSV exportados do TABNET (formato "Colunas separadas por ';'") e monta a base
# de saúde no grão município×ano, espelhando o Monitor SP: casos notificados e óbitos
# por tuberculose, hepatite e HIV. (Decisão: TODOS via TABNET — ver decisoes_metodologicas.md.)
#
# Formato TABNET (verificado): cabeçalho "Município de residência";"2018";...;"Total";
# linhas "430003 ACEGUA";v2018;...;total  (código IBGE 6 díg. + nome; "-" = zero);
# rodapé "Total";... e uma linha final "&" — ambos descartados.
#
# Arquivos esperados em data/raw/nacional/saude/ (qualquer nome; o indicador é
# inferido do nome): *tubercul*/*hepat*/*hiv|aids* × *casos*/*obito|mortal*.
#   ex.: tabnet_tuberculose_casos_rs.csv, tabnet_hiv_obitos_rs.csv
# Ingere apenas os que existirem (roda já só com tuberculose; demais somam depois).
#
# Saída    : data/processed/saude_rs_municipio_ano.csv  (cod_mun6, ano, casos_*, obitos_*)
# Auditoria: outputs/auditoria/saude_cobertura.csv
# =============================================================================

source(here::here("scripts/rs/00_config.R"))
dir_saude <- here::here("data/raw/nacional/saude")

# encoding por bytes (TABNET varia entre UTF-8 e ISO-8859-1)
escolher_encoding <- function(raw) {
  if (stringi::stri_enc_isutf8(raw)) return("UTF-8")
  ruins <- c("Æ","Ø","¡","¢","£","¶","§","ª","º","¿","½","¼","‡")
  cand <- c("ISO-8859-1","CP1252","CP850")
  pont <- vapply(cand, function(e) {
    txt <- tryCatch(stringi::stri_encode(raw, e, "UTF-8"), error = function(...) NA_character_)
    if (length(txt) == 0 || is.na(txt)) return(Inf)
    sum(stringi::stri_count_fixed(txt, ruins))
  }, numeric(1))
  names(pont)[which.min(pont)]
}

# infere indicador a partir do nome do arquivo
indicador_de <- function(arq) {
  n <- stringr::str_to_lower(basename(arq))
  doenca <- dplyr::case_when(stringr::str_detect(n, "tubercul") ~ "tuberculose",
                             stringr::str_detect(n, "hepat")    ~ "hepatite",
                             stringr::str_detect(n, "hiv|aids")  ~ "hiv",
                             TRUE ~ NA_character_)
  tipo <- if (stringr::str_detect(n, "obito|óbito|mortal")) "obitos" else "casos"
  if (is.na(doenca)) NA_character_ else paste0(tipo, "_", doenca)
}

# lê um CSV TABNET -> long (cod_mun6, ano, valor)
ler_tabnet <- function(arq) {
  raw <- readBin(arq, "raw", n = file.info(arq)$size)
  enc <- escolher_encoding(raw)
  txt <- if (enc == "UTF-8") rawToChar(raw) else stringi::stri_encode(raw, enc, "UTF-8")
  Encoding(txt) <- "UTF-8"
  linhas <- stringi::stri_split_lines(txt)[[1]]
  linhas <- linhas[stringr::str_detect(linhas, ";")]            # remove "&" e linhas vazias
  df <- readr::read_delim(I(paste(linhas, collapse = "\n")), delim = ";",
                          show_col_types = FALSE, progress = FALSE,
                          name_repair = "minimal")
  col_mun <- names(df)[1]
  anos_cols <- names(df)[stringr::str_detect(names(df), "^\\d{4}$")]
  df |>
    dplyr::rename(municipio = dplyr::all_of(col_mun)) |>
    dplyr::filter(stringr::str_detect(municipio, "^\\d{6}\\b")) |>   # só linhas de município (descarta "Total")
    dplyr::mutate(cod_mun6 = stringr::str_extract(municipio, "^\\d{6}")) |>
    dplyr::select(cod_mun6, dplyr::all_of(anos_cols)) |>
    tidyr::pivot_longer(dplyr::all_of(anos_cols), names_to = "ano", values_to = "valor") |>
    dplyr::mutate(ano = as.integer(ano),
                  valor = suppressWarnings(as.integer(dplyr::na_if(stringr::str_squish(valor), "-"))),
                  valor = tidyr::replace_na(valor, 0L))
}

arqs <- list.files(dir_saude, pattern = "\\.csv$", full.names = TRUE)
arqs <- arqs[!is.na(vapply(arqs, indicador_de, character(1)))]
if (length(arqs) == 0) stop("Nenhum CSV de saúde reconhecido em ", dir_saude,
                            " (esperado *tubercul*/*hepat*/*hiv* × *casos*/*obito*).")

saude_long <- purrr::map_dfr(arqs, function(a) {
  ind <- indicador_de(a); message("Saúde: ", basename(a), " -> ", ind)
  ler_tabnet(a) |> dplyr::mutate(indicador = ind)
})

saude <- saude_long |>
  dplyr::filter(ano %in% cfg$saude_anos) |>   # recorta a janela (o TABNET às vezes traz anos extras)
  dplyr::group_by(cod_mun6, ano, indicador) |>
  dplyr::summarise(valor = sum(valor, na.rm = TRUE), .groups = "drop") |>
  # values_fill = NA: ano sem dado para um indicador = NÃO DISPONÍVEL (≠ zero real, que vem de "-").
  # Cada indicador tem cobertura temporal própria (ex.: hepatite consolidada só até 2023).
  tidyr::pivot_wider(names_from = indicador, values_from = valor, values_fill = NA) |>
  dplyr::arrange(cod_mun6, ano)

ind_cols <- setdiff(names(saude), c("cod_mun6", "ano"))

# Corte por último ano consolidado de cada indicador: valores além viram NA (provisório).
ano_max_ind <- function(ind) {
  m <- cfg$saude_ano_max[[ind]]
  if (is.null(m)) cfg$saude_ano_max_default else m
}
for (ind in ind_cols) {
  saude[[ind]][saude$ano > ano_max_ind(ind)] <- NA_integer_
}

readr::write_csv(saude, file.path(paths$processed, "saude_rs_municipio_ano.csv"))

# ---- Auditoria ---------------------------------------------------------------
auditoria <- saude |>
  dplyr::group_by(ano) |>
  dplyr::summarise(municipios = dplyr::n_distinct(cod_mun6),
                   # NA (não 0) quando o indicador é provisório/indisponível no ano
                   dplyr::across(dplyr::all_of(ind_cols),
                                 ~ if (all(is.na(.x))) NA_integer_ else sum(.x, na.rm = TRUE)),
                   .groups = "drop")
readr::write_csv(auditoria, file.path(paths$out_aud, "saude_cobertura.csv"))

message("OK — saude_rs_municipio_ano.csv (", nrow(saude), " linhas; indicadores: ",
        paste(ind_cols, collapse = ", "), ") e auditoria gravados.")
print(auditoria)
