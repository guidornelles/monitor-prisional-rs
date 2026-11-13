# =============================================================================
# 05b_export_formato_sp.R — Export das bases no FORMATO do DataStudio de SP
# -----------------------------------------------------------------------------
# Camada de APRESENTAÇÃO: re-emite as bases internas (snake_case, fonte da verdade,
# usadas nos joins/denominadores) com os NOMES "amigáveis" e o FORMATO que o Looker
# de SP já usa, para a importação ser plug-and-play (sem renomear campo a campo).
#
# Princípio: NÃO recalcula indicadores — apenas RENOMEIA/PIVOTA a base interna. Assim
# a interna continua sendo a única fonte da verdade e o export não diverge dela.
#
# Saídas (em outputs/tabelas/formato_sp/), espelhando os arquivos do DataStudio de SP:
#   - contexto_dados.csv     <-> "Variáveis de contexto - dados.csv"        (WIDE)
#   - dinamica_criminal.csv  <-> "Variáveis de contexto - dinamica_criminal.csv" (LONGO)
#   - dados_saude.csv        <-> "Variáveis de contexto - dados_saude.csv"  (LONGO)
#
# Decisões (ver docs/revisao_sintese_e_bases_datastudio.md; Notas Metodológicas de SP):
#   - Contexto: SEM histórico de pop/PIB; PIB = IBGE; distorção = Ens. FUNDAMENTAL; IDEB fora.
#   - munic_ep / ano_ep vêm do 04_contexto (presença e MENOR ano de inauguração do presídio).
#   - tem_EP (criminal) = ano de inauguração do presídio do município (= o que SP faz: 97/97 conferem).
#   - Tem_prisão (saúde) = Sim/Não.
#   - Armas de fogo NÃO entra no criminal municipal (no RS é só estadual: armas_rs_estadual_ano.csv).
#   - Homicídio usa vítimas; flagrantes da PC e mandados VDE têm rótulos próprios.
#   - O total estadual VDE é exportado em arquivo próprio; não é a soma dos municípios completos.
# =============================================================================

source(here::here("scripts/rs/00_config.R"))

dir_out <- file.path(paths$out_tab, "formato_sp")
if (!dir.exists(dir_out)) dir.create(dir_out, recursive = TRUE)
sim_nao <- function(x) dplyr::case_when(is.na(x) ~ NA_character_, x == 1 ~ "Sim", TRUE ~ "Não")

# ---- base de contexto (chaves + munic_ep + ano_ep) ---------------------------
arq_ctx <- file.path(paths$processed, "contexto_rs_municipio.csv")
if (!file.exists(arq_ctx)) stop("Rode 04_contexto.R antes: não achei ", arq_ctx)
ctx <- readr::read_csv(arq_ctx, show_col_types = FALSE)
for (cc in c("munic_ep", "ano_ep")) if (!cc %in% names(ctx)) {
  message("⚠ contexto sem coluna ", cc, " — rode o 04_contexto.R atualizado. Usando NA.")
  ctx[[cc]] <- NA_integer_
}

# ============================== 1) CONTEXTO (wide) ============================
contexto_sp <- ctx |>
  dplyr::transmute(
    `Município`             = paste0(nome, " (RS)"),    # exibição com UF, como SP ("... (SP)")
    `Município (IBGE)`      = nome,                       # nome limpo
    `ID Município`          = id_municipio,
    `Nome Macrorregião`     = nome_regiao_intermediaria,  # rótulo de SP; conteúdo = região intermediária IBGE
    `Pop_2022`              = populacao,                  # só Censo 2022 (sem histórico, por decisão)
    `PIB (em R$)`           = pib,                        # IBGE; ano único (sem série multi-ano)
    `Distorção idade-serie` = distorcao_idade_serie_fund,
    `munic_ep`              = sim_nao(munic_ep)
  ) |>
  dplyr::arrange(`Município (IBGE)`)
readr::write_csv(contexto_sp, file.path(dir_out, "contexto_dados.csv"), na = "")
message("OK — formato_sp/contexto_dados.csv (", nrow(contexto_sp), " municípios; ",
        sum(contexto_sp$munic_ep == "Sim", na.rm = TRUE), " com munic_ep = Sim).")

# ============================== 2) CRIMINAL (longo) ==========================
arq_cri <- file.path(paths$out_tab, "painel_criminal_municipio_ano.csv")
if (file.exists(arq_cri)) {
  cri <- readr::read_csv(arq_cri, show_col_types = FALSE) |>
    dplyr::left_join(dplyr::select(ctx, id_municipio, ano_ep), by = "id_municipio")
  # de-para indicador (largo) -> valor de Crime (SP). Exclui hd_ocorrencias e armas.
  mapa_crime <- tibble::tribble(
    ~col,           ~Crime,
    "hd_vitima",    "Vítimas de homicídio doloso",
    "tot_estupro",  "Estupros - total",
    "roubo_outros", "Total de roubo - outros",
    "furto_outros", "Total de furto - outros",
    "prisoes",      "Flagrantes da Polícia Civil",
    "mandados_cumpridos", "Mandados de prisão cumpridos")
  criminal_sp <- purrr::map_dfr(seq_len(nrow(mapa_crime)), function(i) {
    cc <- mapa_crime$col[i]; nm <- mapa_crime$Crime[i]; tx <- paste0(cc, "_taxa_100k")
    cri |> dplyr::transmute(
      `Município`         = paste0(nom_mun, " (RS)"),
      `Município (IBGE)`  = nom_mun,
      `ID Município`      = id_municipio,
      `Nome Macrorregião` = nome_regiao_intermediaria,
      `Ano`               = ano,
      `Crime`             = nm,
      `quantidade`        = .data[[cc]],
      `população`         = populacao,
      `taxa`              = if (tx %in% names(cri)) .data[[tx]] else NA_real_,
      `tem_EP`            = ano_ep)                       # ano de inauguração do presídio (vazio se não há)
  }) |>
    dplyr::arrange(`Município (IBGE)`, `Crime`, `Ano`)
  readr::write_csv(criminal_sp, file.path(dir_out, "dinamica_criminal.csv"), na = "")
  mandados_uf <- readr::read_csv(file.path(paths$processed, "mandados_rs_estadual_ano.csv"),
                                show_col_types = FALSE)
  readr::write_csv(mandados_uf, file.path(dir_out, "mandados_estadual.csv"), na = "")
  message("OK — formato_sp/dinamica_criminal.csv (", nrow(criminal_sp), " linhas; ",
          dplyr::n_distinct(criminal_sp$Crime), " crimes).")
} else message("(criminal) ", basename(arq_cri), " ausente — pulado (rode 02_criminal + 05).")

# ============================== 3) SAÚDE (longo) =============================
arq_sau <- file.path(paths$out_tab, "painel_saude_municipio_ano.csv")
if (file.exists(arq_sau)) {
  sau <- readr::read_csv(arq_sau, show_col_types = FALSE) |>
    dplyr::left_join(dplyr::select(ctx, id_municipio, munic_ep), by = "id_municipio")
  # A expansão da cobertura em 2025 é exclusiva de TB. Anexa seus novos registros
  # ao final para permitir a atualização da fonte conectada sem reordenar linhas.
  if (!"tb_2025_complementar" %in% names(sau)) sau$tb_2025_complementar <- FALSE
  mapa_tipo <- tibble::tribble(
    ~col,                 ~Tipo,
    "casos_hiv",          "Casos_HIV",
    "casos_tuberculose",  "Casos_tub",
    "casos_hepatite",     "Casos_Hepatite",
    "obitos_hiv",         "morte_HIV",
    "obitos_tuberculose", "morte_tub",
    "obitos_hepatite",    "morte_Hepatite")
  saude_sp <- purrr::map_dfr(seq_len(nrow(mapa_tipo)), function(i) {
    cc <- mapa_tipo$col[i]; tp <- mapa_tipo$Tipo[i]
    sau |>
      dplyr::filter(!tb_2025_complementar | tp == "Casos_tub") |>
      dplyr::transmute(
      `Município`         = paste0(nom_mun, " (RS)"),
      `Município (IBGE)`  = nom_mun,
      `ID Município`      = id_municipio,
      `Nome Macrorregião` = nome_regiao_intermediaria,
      `Ano`               = ano,
      `Tipo`              = tp,
      `quantidade`        = .data[[cc]],                  # NA (vazio) = ano não consolidado p/ o indicador
      `Tem_prisão`        = sim_nao(munic_ep),
      tb_2025_complementar)
  }) |>
    dplyr::arrange(tb_2025_complementar, `Município (IBGE)`, `Tipo`, `Ano`) |>
    dplyr::select(-tb_2025_complementar)
  # SP não tem população/taxa na saúde (só quantidade + Tem_prisão) — espelhado aqui.
  readr::write_csv(saude_sp, file.path(dir_out, "dados_saude.csv"), na = "")
  message("OK — formato_sp/dados_saude.csv (", nrow(saude_sp), " linhas; ",
          dplyr::n_distinct(saude_sp$Tipo), " tipos).")
} else message("(saúde) ", basename(arq_sau), " ausente — pulado (rode 04b_saude + 05).")

message("Export formato-SP concluído em ", dir_out, ".")
