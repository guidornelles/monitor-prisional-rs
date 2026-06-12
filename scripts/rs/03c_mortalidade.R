# =============================================================================
# 03c_mortalidade.R — Mortalidade no sistema prisional (SISDEPEN, 2º semestre)
# -----------------------------------------------------------------------------
# Reproduz a camada de mortalidade do Monitor SP (seção 6.8 do SISDEPEN). Conforme
# a Nota Metodológica de SP (e o script dados_sem2.R da branch atual), a mortalidade
# usa o **2º semestre** de cada ano (≠ das demais camadas prisionais, que usam o 1º).
#
# Fonte: Base Única SISDEPEN, RS, **2º semestre**, cela física, anos de cfg$anos.
# Saída: data/processed/prisional_mortalidade_rs.csv (id, periodo, obitos_*_{m,f,total})
#   tipos: naturais (saúde), criminais, suicídios, acidentais, causa desconhecida.
# =============================================================================

source(here::here("scripts/rs/00_config.R"))
norm_txt <- function(x) stringi::stri_trans_general(stringr::str_squish(stringr::str_to_lower(x)), "Latin-ASCII")

arq <- arquivo_baseunica()
message("Base Única (2º sem p/ mortalidade): ", basename(arq))
df <- suppressWarnings(readxl::read_excel(arq, sheet = 1, guess_max = 10000))
ref_alvo <- paste0(cfg$anos, "/2")                       # 2º semestre
df <- df |>
  dplyr::mutate(UF = toupper(.data[["UF"]]), ref = as.character(.data[["Referência"]])) |>
  dplyr::filter(UF == cfg$uf, ref %in% ref_alvo)
if ("Tipo de Recolhimento" %in% names(df))
  df <- dplyr::filter(df, norm_txt(.data[["Tipo de Recolhimento"]]) == "cela fisica")
df <- df |> dplyr::mutate(
  ano = as.integer(stringr::str_extract(ref, "^\\d{4}")),
  periodo = as.character(ano),
  id = paste(`Nome do Estabelecimento`, UF, ano, sep = "-"),
  dplyr::across(where(is.numeric), ~ ifelse(is.na(.), 0, .)))

nomes <- names(df)
col_obito <- function(tipo_tokens, Sx) {
  ok <- nomes[grepl("6.8 Mortalidade", nomes, fixed = TRUE) &
              vapply(nomes, function(n) all(vapply(tipo_tokens, function(t) grepl(t, n, fixed = TRUE), logical(1))), logical(1)) &
              endsWith(nomes, paste0("| ", Sx))]
  if (length(ok) != 1) stop("Coluna 6.8 não única para ", paste(tipo_tokens, collapse="+"), " | ", Sx, " (", length(ok), ")")
  df[[ok]]
}
tipos <- list(naturais = "Óbitos naturais", criminais = "Óbitos criminais",
              suicidios = "Óbitos suicídios", acidentais = "Óbitos acidentais",
              desconhecida = "Óbitos com causa desconhecida")
mort <- tibble::tibble(id = df$id, periodo = df$periodo)
for (tk in names(tipos)) for (sx in c("masculino","feminino","total")) {
  Sx <- c(masculino="Masculino", feminino="Feminino", total="Total")[[sx]]
  mort[[paste0("obitos_", tk, "_", sx)]] <- col_obito(tipos[[tk]], Sx)
}
mort$obitos_total_geral <- rowSums(dplyr::select(mort, dplyr::ends_with("_total")))

readr::write_csv(mort, file.path(paths$processed, "prisional_mortalidade_rs.csv"))
auditoria <- mort |> dplyr::group_by(periodo) |>
  dplyr::summarise(estab = dplyr::n(), obitos_total = sum(obitos_total_geral), .groups = "drop")
readr::write_csv(auditoria, file.path(paths$out_aud, "prisional_mortalidade_cobertura.csv"))
message("OK — prisional_mortalidade_rs.csv (", nrow(mort), " linhas) e auditoria gravados.")
print(auditoria)
