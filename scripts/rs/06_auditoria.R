# =============================================================================
# 06_auditoria.R — Auditoria consolidada dos painéis RS
# -----------------------------------------------------------------------------
# Reúne num só lugar as auditorias de todas as etapas + um diagnóstico de qualidade
# dos painéis finais. Não recalcula as fontes: lê os artefatos de auditoria já
# gravados por 02–05 e os painéis da mesma execução. Grava na pasta de auditoria:
#   - RELATORIO_AUDITORIA.md     (relatório legível)
#   - qualidade_paineis.csv     (NAs/zeros por coluna de cada painel)
#
# Uso:  source("scripts/rs/06_auditoria.R")  (após rodar 02–05)
# =============================================================================

source(here::here("scripts/rs/00_config.R"))
dir_aud <- paths$out_aud
dir_tab <- paths$out_tab

# ---- helpers -----------------------------------------------------------------
df_md <- function(df) {                              # tibble -> tabela markdown
  if (is.null(df) || nrow(df) == 0) return("_(arquivo ausente ou vazio)_")
  fmt <- function(x) {
    s <- ifelse(is.na(x), "NA", format(x, trim = TRUE, big.mark = ".", decimal.mark = ","))
    gsub("|", "/", s, fixed = TRUE)                  # escapa "|" (separador de célula) nos nomes SISDEPEN
  }
  cab <- paste0("| ", paste(names(df), collapse = " | "), " |")
  sep <- paste0("| ", paste(rep("---", ncol(df)), collapse = " | "), " |")
  linhas <- vapply(seq_len(nrow(df)),
                   function(i) paste0("| ", paste(vapply(df[i, ], fmt, character(1)), collapse = " | "), " |"),
                   character(1))
  paste(c(cab, sep, linhas), collapse = "\n")
}
ler_aud <- function(nome) {
  p <- file.path(dir_aud, nome)
  if (file.exists(p)) readr::read_csv(p, show_col_types = FALSE) else NULL
}
secao <- function(titulo, nome_arq, descr = NULL) {
  d <- ler_aud(nome_arq)
  c(paste0("## ", titulo),
    if (!is.null(descr)) c("", descr) else NULL,
    "", paste0("Fonte: [", nome_arq, "](", nome_arq, ")"),
    "", df_md(d), "")
}

# ---- diagnóstico de qualidade dos painéis (NAs/zeros por coluna) -------------
resumo_painel <- function(nome) {
  p <- file.path(dir_tab, nome)
  if (!file.exists(p)) return(NULL)
  d <- readr::read_csv(p, show_col_types = FALSE)
  num <- names(d)[vapply(d, is.numeric, logical(1))]
  if (length(num) == 0) return(NULL)
  tibble::tibble(
    painel = nome,
    coluna = num,
    n = nrow(d),
    n_na = vapply(num, function(c) sum(is.na(d[[c]])), integer(1)),
    n_zero = vapply(num, function(c) sum(d[[c]] == 0, na.rm = TRUE), integer(1))
  )
}
paineis <- c("painel_criminal_municipio_ano.csv", "painel_prisional_estabelecimento.csv",
             "painel_contexto_municipio.csv", "painel_saude_municipio_ano.csv")
qualidade <- purrr::map_dfr(paineis, resumo_painel)
if (nrow(qualidade)) readr::write_csv(qualidade, file.path(dir_aud, "qualidade_paineis.csv"))

# inventário dos painéis (existência + dimensões)
inv_painel <- purrr::map_dfr(paineis, function(nm) {
  p <- file.path(dir_tab, nm)
  if (!file.exists(p)) return(tibble::tibble(painel = nm, existe = FALSE, linhas = NA_integer_, colunas = NA_integer_))
  d <- readr::read_csv(p, show_col_types = FALSE)
  tibble::tibble(painel = nm, existe = TRUE, linhas = nrow(d), colunas = ncol(d))
})

# ---- montagem do relatório ---------------------------------------------------
rel <- c(
  "# Relatório de auditoria do Monitor Prisional RS",
  paste0("_Gerado por `06_auditoria.R` em ", as.character(Sys.time()), "._"),
  "",
  "Consolida as auditorias de cada etapa do pipeline (02–05) e diagnostica a",
  "qualidade dos painéis finais. As decisões metodológicas que explicam cada",
  "recorte estão em `docs/decisoes_metodologicas.md`.",
  "",
  "## Painéis finais (inventário)", "", df_md(inv_painel), "",
  secao("Reconciliação criminal (microdado × agregado oficial)", "criminal_reconciliacao.csv",
        "Δ% compara a reconstrução com o agregado oficial. A versão revista de 2022 substitui a antiga; consulte os resíduos em criminal_reconciliacao_municipal.csv."),
  secao("Prisões em flagrante (PC) — cobertura municipal", "prisoes_cobertura.csv"),
  secao("Mandados de prisão cumpridos (Sinesp VDE)", "mandados_sinesp_cobertura_anual.csv",
        "Série própria. Total municipal anual exige 12 meses; total estadual usa a base original e inclui registros não localizados ou de municípios com cobertura parcial."),
  secao("Prisional (SISDEPEN Base Única) — cobertura cela física", "prisional_cobertura.csv"),
  secao("Contexto — cobertura município/região/denominadores", "contexto_cobertura.csv"),
  secao("Saúde (DATASUS/TABNET) — cobertura por indicador e ano", "saude_cobertura.csv",
        "NA = sem valor publicado para o recorte. Casos de hepatite até 2023; aids e óbitos até 2024; casos de tuberculose até 2025 na extração de maio de 2026."),
  secao("Planilha final — cobertura e pareamento", "planilha_final_cobertura.csv",
        "`nomes_sem_match` = nomes da SSP sem correspondência no IBGE (esperado: municípios de outras UFs)."),
  "## Municípios sem pareamento (SSP → IBGE)",
  "", "A tabela de [pareamento](match_municipios.csv) ajuda a conferir nomes de outras UFs, aliases e linhas que não representam municípios.",
  "", df_md(ler_aud("match_municipios.csv")), "",
  "## Qualidade dos painéis (NAs e zeros por coluna)",
  "", "Fonte: [qualidade_paineis.csv](qualidade_paineis.csv).",
  "Na saúde, NA indica valor não disponível; zero exige informação da fonte.",
  "", df_md(qualidade), "",
  "## Ressalvas conhecidas (ver docs/decisoes_metodologicas.md)",
  "",
  "- **Criminal:** 2022–2025. Ocorrências de estupro e patrimônio; vítimas para homicídio doloso. A ausência de registro na junção não vira zero.",
  "- **`prisoes` = flagrantes da PC.** Mandados do VDE são série separada, sem soma com flagrantes.",
  "- **Armas:** agregado estadual; a série municipal 2022–2025 ainda não está disponível.",
  "- **Prisional:** 2017–2025 em cela física; estoque do 1º semestre e óbitos anuais quando informados. Ver a cobertura em validacao_prisional.md.",
  "- **Saúde:** cobertura específica por indicador; confira a extração e os cortes da execução.",
  "- **Taxas por 100 mil:** população definitiva do Censo 2022 como denominador fixo; a taxa não incorpora mudanças populacionais ano a ano."
)
saida <- file.path(dir_aud, "RELATORIO_AUDITORIA.md")
readr::write_lines(rel, saida)

message("OK — relatório consolidado: ", saida)
message("     qualidade dos painéis: ", file.path(dir_aud, "qualidade_paineis.csv"))
print(inv_painel)
