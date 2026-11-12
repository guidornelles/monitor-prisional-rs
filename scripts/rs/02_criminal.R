# =============================================================================
# 02_criminal.R — Camada criminal municipal do Monitor RS
# -----------------------------------------------------------------------------
# Constrói indicadores anuais por município com extrações versionadas da SSP-RS.
# Homicídio no painel conta vítimas do agregado oficial; os microdados fornecem
# ocorrências consumadas e as composições estritas de roubo e furto.
#
# Entrada : microdados e indicadores oficiais definidos em data/raw/ssp_rs_fontes.csv
# Saída   : data/processed/criminal_rs_municipio_ano.csv
# Auditoria: outputs/auditoria/criminal_reconciliacao.csv  (microdado x oficial)
#
# Variáveis no padrão SP: nom_mun, hd_vitima, tot_estupro, roubo_outros, furto_outros
# (+ hd_ocorrencias, extra para a discussão com a equipe SP sobre 'hd_vitima').
# =============================================================================

source(here::here("scripts/rs/00_config.R"))
source(here::here("R/funcoes_criminal.R"))

# ---- Localiza a tabela oficial na versão do catálogo e confirma a aba ----------
arquivo_oficial <- function(ano) {
  arq <- fonte_ssp("indicadores_criminais", ano)
  if (!file.exists(arq) || !as.character(ano) %in% readxl::excel_sheets(arq))
    stop("Tabela oficial com aba ", ano, " não encontrada: ", arq)
  arq
}

# Lê a aba do ano detectando a linha de cabeçalho (1ª coluna começa com "Munic").
ler_oficial <- function(ano) {
  arq <- arquivo_oficial(ano)
  bruto <- read_excel(arq, sheet = as.character(ano), col_names = FALSE, n_max = 15,
                      .name_repair = "minimal")
  lin_hdr <- which(stringr::str_starts(normalizar_municipio(bruto[[1]]), "MUNIC"))[1]
  df <- suppressMessages(read_excel(arq, sheet = as.character(ano), skip = lin_hdr - 1)) |>
    rename_with(str_squish)
  df |>
    mutate(municipio = normalizar_municipio(.data[["Municípios"]])) |>
    filter(municipio_valido(municipio)) |>
    transmute(
      municipio,
      hd_vitima      = as.numeric(.data[["Total de vítimas de Homicidio Doloso"]]),
      # NB: a coluna oficial é "Homicídio  Doloso" (espaço duplo), mas a linha 37
      # aplica rename_with(str_squish), que colapsa para espaço simples. Por isso
      # referenciamos aqui o nome JÁ normalizado (simples), senão o lookup falha.
      of_hd_oco      = as.numeric(.data[["Homicídio Doloso"]]),
      of_furtos      = as.numeric(.data[["Furtos"]]),
      of_roubos      = as.numeric(.data[["Roubos"]])
    )
}

# ---- Processa todos os anos --------------------------------------------------
crim <- purrr::map_dfr(cfg$anos_criminal, function(ano) {
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

readr::write_csv(crim |>
  dplyr::transmute(municipio, ano, hd_ocorrencias, of_hd_oco, furtos_total, of_furtos,
                   roubos_total, of_roubos, roubo_outros, furto_outros,
                   d_hd = hd_ocorrencias - of_hd_oco,
                   d_furtos = furtos_total - of_furtos, d_roubos = roubos_total - of_roubos),
  file.path(paths$out_aud, "criminal_reconciliacao_municipal.csv"), na = "")
