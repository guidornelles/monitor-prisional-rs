# =============================================================================
# 02b_atividade.R — Prisões em flagrante (PC) por município × ano
# -----------------------------------------------------------------------------
# Flagrantes da PC, sem equivalência ao total paulista. Fonte: Lei 15.610/2021,
# Art. 6º Inc. IX — "Prisões em Flagrante pela PC por Fato e Município" (um arquivo
# por semestre). O arquivo registra fatos com flagrante, sem quantidade de
# pessoas. A série conta linhas por município do fato e ano de referência.
#
# RECORTE / LIMITES (decisões consolidadas; ver docs/decisoes_metodologicas.md):
#   - `prisoes` preserva o nome interno legado e conta registros de flagrantes.
#     Mandados do Sinesp entram como série própria no 02c; não somar as duas fontes.
#   - Armas ficam no agregado estadual: os anexos municipais não dão série 2022–2025.
#
# Entrada : data/raw/ssp_rs/semestrais/AAAA_Nsem/.../*Prisoes em Flagrante*Municipio*.csv
# Saída   : data/processed/prisoes_rs_municipio_ano.csv  (municipio_key, nom_mun, ano, prisoes)
# Auditoria: outputs/auditoria/prisoes_cobertura.csv
# =============================================================================

source(here::here("scripts/rs/00_config.R"))

norm_txt <- function(x) stringi::stri_trans_general(stringr::str_squish(stringr::str_to_upper(x)), "Latin-ASCII")

# Seletor de encoding por bytes: os CSVs de flagrante variam entre UTF-8 e CP850 (DOS).
# O readr::guess_encoding NÃO detecta CP850; lê-lo como latin1 gera mojibake ("SÆO LEOPOLDO")
# que vira chave duplicada de município. Escolhemos o encoding que produz menos caracteres
# "suspeitos" (típicos de CP850 mal-decodificado). Validado: 2022 deixa de inflar (558->438).
escolher_encoding <- function(raw) {
  if (stringi::stri_enc_isutf8(raw)) return("UTF-8")
  ruins <- c("Æ","Ø","¡","¢","£","¶","§","ª","º","¿","½","¼","‡")
  cand <- c("CP850", "CP1252", "ISO-8859-1")
  pont <- vapply(cand, function(e) {
    txt <- tryCatch(stringi::stri_encode(raw, e, "UTF-8"), error = function(...) NA_character_)
    if (length(txt) == 0 || is.na(txt)) return(Inf)
    sum(stringi::stri_count_fixed(txt, ruins))
  }, numeric(1))
  names(pont)[which.min(pont)]
}

# Localiza os CSVs de flagrante (nomes irregulares); ano vem da pasta AAAA_Nsem.
arqs <- list.files(paths$ssp_root, pattern = "Prisoes em Flagrante.*Municipio.*\\.csv$",
                   recursive = TRUE, full.names = TRUE, ignore.case = TRUE)
mapa <- tibble::tibble(
  arq = arqs,
  ano = as.integer(stringr::str_extract(arq, "(\\d{4})(?=_\\dsem)")),
  sem = as.integer(stringr::str_extract(arq, "(?<=\\d{4}_)\\d(?=sem)"))
) |>
  dplyr::filter(ano %in% cfg$anos_criminal) |>
  dplyr::arrange(ano, sem)

stopifnot(!anyDuplicated(mapa[c("ano", "sem")]),
          nrow(mapa) == 2L * length(cfg$anos_criminal),
          all(mapa$sem %in% 1:2))

ler_flagrantes <- function(arq, ano) {
  raw <- readBin(arq, "raw", n = file.info(arq)$size)
  enc <- escolher_encoding(raw)
  txt <- if (enc == "UTF-8") rawToChar(raw) else stringi::stri_encode(raw, enc, "UTF-8")
  Encoding(txt) <- "UTF-8"
  linhas <- stringi::stri_split_lines(txt)[[1]]
  # Alguns arquivos têm bloco de título (ESTADO DO RS / POLÍCIA CIVIL / ...) antes do
  # cabeçalho real. Detecta a linha de cabeçalho (contém "Municipio" + "Fato/Data") e pula.
  h <- which(stringr::str_detect(linhas, stringr::regex("munic", ignore_case = TRUE)) &
             stringr::str_detect(linhas, stringr::regex("fato|data registro", ignore_case = TRUE)))[1]
  if (is.na(h)) h <- 1L
  df <- readr::read_delim(I(paste(linhas[h:length(linhas)], collapse = "\n")),
                          delim = ";", show_col_types = FALSE, progress = FALSE)
  # localiza colunas por padrão (cabeçalhos podem variar levemente)
  col_mun <- names(df)[stringr::str_detect(names(df), stringr::regex("munic.*fato|^munic", ignore_case = TRUE))][1]
  col_tipo <- names(df)[stringr::str_detect(names(df), stringr::regex("tipo.*ocorr", ignore_case = TRUE))][1]
  if (is.na(col_mun)) stop("Coluna de município não encontrada em: ", basename(arq))
  df <- dplyr::rename(df, municipio = dplyr::all_of(col_mun))
  if (!is.na(col_tipo))  # garante só flagrantes (o arquivo já é de flagrantes, mas confirmamos)
    df <- dplyr::filter(df, stringr::str_detect(norm_txt(.data[[col_tipo]]), "FLAGRANTE"))
  df |>
    dplyr::filter(!is.na(municipio), norm_txt(municipio) != "", !norm_txt(municipio) %in% c("RS","TOTAL","NAO INFORMADO","NAO INFORMADO/OUTROS ESTADOS")) |>
    dplyr::transmute(municipio_key = norm_txt(municipio), nom_mun = municipio, ano = ano)
}

flagr <- purrr::pmap_dfr(mapa[, c("arq","ano")], function(arq, ano) {
  message("Flagrantes ", ano, " — ", basename(arq))
  ler_flagrantes(arq, ano)
})

prisoes <- flagr |>
  dplyr::group_by(municipio_key, ano) |>
  dplyr::summarise(nom_mun = dplyr::first(nom_mun), prisoes = dplyr::n(), .groups = "drop") |>
  dplyr::select(municipio_key, nom_mun, ano, prisoes) |>
  dplyr::arrange(municipio_key, ano)

readr::write_csv(prisoes, file.path(paths$processed, "prisoes_rs_municipio_ano.csv"))

# ---- Auditoria ---------------------------------------------------------------
auditoria <- prisoes |>
  dplyr::group_by(ano) |>
  dplyr::summarise(municipios = dplyr::n_distinct(municipio_key),
                   total_prisoes = sum(prisoes), .groups = "drop")
readr::write_csv(auditoria, file.path(paths$out_aud, "prisoes_cobertura.csv"))

message("OK — prisoes_rs_municipio_ano.csv (", nrow(prisoes), " linhas) e auditoria gravados.")
print(auditoria)
