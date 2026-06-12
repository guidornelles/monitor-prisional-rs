# =============================================================================
# 02_criminal.R — Camada criminal municipal do Monitor RS
# -----------------------------------------------------------------------------
# Constrói os indicadores criminais por município x ano a partir dos MICRODADOS
# Mensais da SSP-RS (regras validadas na PoC), no padrão de variáveis do Monitor SP.
#
# Entrada : data/EstatisticasCriminaisRS/DadosAbertos/Mensais/*JAN_DEZ_AAAA*.csv
#           data/EstatisticasCriminaisRS/IndicadoresCriminais/*ano-AAAA*.xlsx (oficial)
# Saída   : data/processed/criminal_rs_municipio_ano.csv
# Auditoria: outputs/auditoria/criminal_reconciliacao.csv  (microdado x oficial)
#
# Variáveis no padrão SP: nom_mun, hd_vitima, tot_estupro, roubo_outros, furto_outros
# (+ hd_ocorrencias, extra para a discussão com a equipe SP sobre 'hd_vitima').
# =============================================================================

source(here::here("scripts/rs/00_config.R"))
source(here::here("R/funcoes_criminal.R"))

# ---- Localiza a tabela oficial de Indicadores Criminais de um ano ------------
# Seleciona pela PRESENÇA da aba do ano (robusto: o nome do arquivo às vezes traz a
# data de atualização, não o ano dos dados — armadilha detectada na PoC).
arquivo_oficial <- function(ano) {
  arqs <- list.files(paths$ind_crim, pattern = "\\.xlsx$", full.names = TRUE, recursive = TRUE)
  cand <- arqs[str_detect(basename(arqs), regex("munic", ignore_case = TRUE)) &
               !str_detect(basename(arqs), regex("mulher|violencia", ignore_case = TRUE))]
  ok <- cand[purrr::map_lgl(cand, ~ as.character(ano) %in% readxl::excel_sheets(.x))]
  if (length(ok) == 0) stop("Tabela oficial com aba ", ano, " não encontrada")
  ok[which.max(file.info(ok)$size)]
}

# Lê a aba do ano detectando a linha de cabeçalho (1ª coluna começa com "Munic").
ler_oficial <- function(ano) {
  arq <- arquivo_oficial(ano)
  bruto <- read_excel(arq, sheet = as.character(ano), col_names = FALSE, n_max = 15)
  lin_hdr <- which(stringr::str_starts(normalizar_municipio(bruto[[1]]), "MUNIC"))[1]
  df <- read_excel(arq, sheet = as.character(ano), skip = lin_hdr - 1) |>
    rename_with(str_squish)
  df |>
    mutate(municipio = normalizar_municipio(.data[["Municípios"]])) |>
    filter(!eh_nao_municipio(municipio)) |>
    transmute(
      municipio,
      hd_vitima      = as.numeric(.data[["Total de vítimas de Homicidio Doloso"]]),
      of_hd_oco      = as.numeric(.data[["Homicídio  Doloso"]]),
      of_furtos      = as.numeric(.data[["Furtos"]]),
      of_roubos      = as.numeric(.data[["Roubos"]])
    )
}

# ---- Processa todos os anos --------------------------------------------------
crim <- purrr::map_dfr(cfg$anos, function(ano) {
  message("Processando criminal ", ano, " ...")
  micro <- ler_microdado(arquivo_microdado(ano), cfg$escolhas$consumado_apenas)
  rec   <- agregar_criminal(micro, ano)
  ofi   <- ler_oficial(ano) |> mutate(ano = ano)
  dplyr::full_join(rec, ofi, by = c("municipio", "ano"))
})

# ---- Tabela final (padrão SP) ------------------------------------------------
criminal_final <- crim |>
  transmute(
    nom_mun = municipio, ano,
    hd_vitima,                    # oficial (Total de vítimas de HD) — decisão metodológica
    hd_ocorrencias,               # microdado (extra; ver decisões §homicídio)
    tot_estupro, roubo_outros, furto_outros
  ) |>
  arrange(nom_mun, ano)

readr::write_csv(criminal_final, file.path(paths$processed, "criminal_rs_municipio_ano.csv"))

# ---- Auditoria: reconciliação microdado x oficial ----------------------------
# Compara os TOTAIS reconstruídos (roubos_total/furtos_total) com a coluna oficial
# (valida o pipeline). O "outros estrito" não bate com o oficial por construção
# (exclui banco/comércio/carga) — por isso reportamos também a diferença estrito x total.
auditoria <- crim |>
  group_by(ano) |>
  summarise(
    hd_oco_micro = sum(hd_ocorrencias, na.rm = TRUE), hd_oco_ofi = sum(of_hd_oco, na.rm = TRUE),
    furtos_total_micro = sum(furtos_total, na.rm = TRUE), furtos_ofi = sum(of_furtos, na.rm = TRUE),
    roubos_total_micro = sum(roubos_total, na.rm = TRUE), roubos_ofi = sum(of_roubos, na.rm = TRUE),
    roubo_outros_estrito = sum(roubo_outros, na.rm = TRUE),
    furto_outros_estrito = sum(furto_outros, na.rm = TRUE),
    .groups = "drop"
  ) |>
  mutate(
    d_hd_pct     = round((hd_oco_micro - hd_oco_ofi) / hd_oco_ofi * 100, 2),
    d_furtos_pct = round((furtos_total_micro - furtos_ofi) / furtos_ofi * 100, 2),
    d_roubos_pct = round((roubos_total_micro - roubos_ofi) / roubos_ofi * 100, 2)
  )
readr::write_csv(auditoria, file.path(paths$out_aud, "criminal_reconciliacao.csv"))
message("OK — criminal_rs_municipio_ano.csv e auditoria gravados.")
print(auditoria)
