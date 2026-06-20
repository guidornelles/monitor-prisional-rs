# =============================================================================
# 07_validacao_prisional.R — Validação da camada prisional CORRIGIDA
# -----------------------------------------------------------------------------
# Confere as correções D1–D6 (ver docs/plano_correcoes_prisional_poc.md):
#   1) Cobertura por ano (esperado: 104 / 103 / 104 / 103 estabelecimentos).
#   2) Óbitos ANUAIS (1º+2º sem) — devem ser MAIORES que a versão antiga só-2º-sem
#      (baseline antigo, p/ comparação: 2022=69, 2023=52, 2024=61, 2025=81).
#   3) Paridade de NOMES com a base do DataStudio de SP (conceito do validation/analysis.R):
#      quais colunas do DataStudio o painel do RS já tem / ainda faltam / são extras.
#   4) Checagens de consistência interna (não dependem de SP):
#      - obitos_*_total == masculino + feminino  (por linha);
#      - tipo_penal_outros_* >= 0  (partição residual sem dupla contagem);
#      - continentes (soma) <= estrangeiros (5.8 | Estrangeiros - total | M+F);
#      - faixas de pena: soma das 8 faixas (M+F) == condenados com tempo de pena.
#
# Rodar DEPOIS do pipeline (após 05). Saída: outputs/auditoria/validacao_prisional.md
# =============================================================================

source(here::here("scripts/rs/00_config.R"))

ok  <- function(x) if (isTRUE(x)) "OK" else "FALHA"
linhas <- character(0)
add <- function(...) { l <- paste0(...); message(l); linhas <<- c(linhas, l) }

add("# Validação da camada prisional — ", format(Sys.time(), "%Y-%m-%d %H:%M"))

# ---- Carrega saídas ----------------------------------------------------------
arq_painel <- file.path(paths$out_tab, "painel_prisional_estabelecimento.csv")
arq_der    <- file.path(paths$processed, "prisional_derivadas_rs.csv")
if (!file.exists(arq_painel)) stop("Rode o pipeline (05) antes: não achei ", arq_painel)
painel <- readr::read_csv(arq_painel, show_col_types = FALSE)
der    <- if (file.exists(arq_der)) readr::read_csv(arq_der, show_col_types = FALSE) else painel

ano_col <- intersect(c("ano","periodo"), names(painel))[1]
painel$.ano <- as.integer(painel[[ano_col]])

# ---- 1) Cobertura por ano ----------------------------------------------------
add("\n## 1. Cobertura por ano (esperado 104/103/104/103)")
cob <- painel |> dplyr::count(.ano, name = "estab") |> dplyr::arrange(.ano)
esperado <- c(`2022`=104L, `2023`=103L, `2024`=104L, `2025`=103L)
for (i in seq_len(nrow(cob))) {
  a <- as.character(cob$.ano[i]); e <- esperado[a]
  add("  ", a, ": ", cob$estab[i], " estab", if (!is.na(e)) paste0("  (esperado ", e, " — ", ok(cob$estab[i]==e), ")") else "")
}

# ---- 2) Óbitos anuais (devem subir vs baseline antigo só-2º-sem) --------------
add("\n## 2. Óbitos ANUAIS por ano (1º+2º sem) vs baseline antigo (só 2º sem)")
baseline_antigo <- c(`2022`=69L, `2023`=52L, `2024`=61L, `2025`=81L)
ob_tot_cols <- grep("^obitos_.*_total$", names(painel), value = TRUE)
if (length(ob_tot_cols)) {
  ob <- painel |> dplyr::group_by(.ano) |>
    dplyr::summarise(obitos_total = sum(dplyr::across(dplyr::all_of(ob_tot_cols)), na.rm = TRUE), .groups="drop")
  for (i in seq_len(nrow(ob))) {
    a <- as.character(ob$.ano[i]); b <- baseline_antigo[a]
    flag <- if (!is.na(b)) paste0("  (antigo só-2º-sem=", b, "; anual ", ifelse(ob$obitos_total[i] >= b, "≥ ✓", "< ✗ — investigar"), ")") else ""
    add("  ", a, ": ", ob$obitos_total[i], " óbitos", flag)
  }
  add("  > Esperado: o total ANUAL é ≥ o antigo (que pegava só o 2º semestre).")
} else add("  ⚠ não achei colunas obitos_*_total no painel (rode 03b/05).")

# ---- 3) Paridade de nomes com a base do DataStudio de SP ---------------------
add("\n## 3. Paridade de nomes com a base do DataStudio de SP")
arq_ds <- file.path(paths$raw, "bases_data_studio", "base_sisdepen - Sheet1.csv")
if (file.exists(arq_ds)) {
  ds_cols <- names(readr::read_csv(arq_ds, n_max = 0, show_col_types = FALSE))
  p_cols  <- names(painel)
  # foco nas DERIVADAS amigáveis de SP (não nas ~530 brutas); checa as que mais importam
  alvo <- c("provisorios_masculino","sentenciado_fechado_masculino","tratamento_feminino",
            "pena_masculino_0_2anos","pena_masculino_2_4anos","pena_masculino_30_maisanos",
            "pena_remanescente_masculino_0_4anos",
            "obitos_saude_total","obitos_suicidio_total","obitos_criminais_total",
            "obitos_acidentais_total","obitos_desconhecida_total",
            "continente_america","continente_asia","continente_africa","continente_europa","continente_oceania",
            "atendimento_estabelecimento","atendimento_externo","atendimento_odonto",
            "cela_gestantes","quantidade_lactantes",
            "mulheres_presas_com_filhos_as","homens_presos_com_filhos_as",
            "tipo_penal_contra_pessoa_total","tipo_penal_outros_total")
  alvo_ds <- intersect(alvo, ds_cols)         # alvos que existem na base de SP
  faltam  <- setdiff(alvo_ds, p_cols)         # SP tem e nosso painel ainda não
  add("  derivadas-alvo presentes no painel: ", length(intersect(alvo_ds, p_cols)), "/", length(alvo_ds), " (", ok(length(faltam)==0), ")")
  if (length(faltam)) add("  FALTAM (SP tem, painel não): ", paste(faltam, collapse=", "))
  # nomes antigos que NÃO devem mais existir (pegadinha da correção D2)
  proibidos <- intersect(c("obitos_naturais_total","obitos_suicidios_total","obitos_total_geral",
                           "pena_masculino_0_4anos","pena_masculino_1_8anos"), p_cols)
  add("  nomes ANTIGOS remanescentes (deviam sumir): ", if (length(proibidos)) paste(proibidos, collapse=", ") else "nenhum", "  (", ok(length(proibidos)==0), ")")
} else add("  ⚠ base do DataStudio não encontrada em ", arq_ds, " — pulo a paridade de nomes.")

# ---- 4) Consistência interna -------------------------------------------------
add("\n## 4. Checagens de consistência interna")
# 4a) obitos_*_total == masculino + feminino
tipos <- c("saude","criminais","suicidio","acidentais","desconhecida")
difs <- 0L
for (tk in tipos) {
  cm <- paste0("obitos_",tk,"_masculino"); cf <- paste0("obitos_",tk,"_feminino"); ct <- paste0("obitos_",tk,"_total")
  if (all(c(cm,cf,ct) %in% names(painel)))
    difs <- difs + sum(abs(painel[[ct]] - (painel[[cm]] + painel[[cf]])) > 0.5, na.rm = TRUE)
}
add("  4a) obitos_total == M+F: ", difs, " linha(s) divergente(s)  (", ok(difs==0), ")")
# 4b) tipo_penal_outros_* >= 0
neg <- 0L
for (TT in c("masculino","feminino","total")) { c <- paste0("tipo_penal_outros_",TT)
  if (c %in% names(painel)) neg <- neg + sum(painel[[c]] < 0, na.rm = TRUE) }
add("  4b) tipo_penal_outros >= 0 (residual): ", neg, " negativo(s)  (", ok(neg==0), ")")
# 4c) continentes (soma) <= estrangeiros (5.8 | Estrangeiros - total | M+F)
estr <- grep("5.8.*Estrangeiros - total.*\\| (Masculino|Feminino)$", names(painel), value = TRUE)
cont <- grep("^continente_", names(painel), value = TRUE)
if (length(estr) >= 1 && length(cont) >= 1) {
  soma_cont <- rowSums(dplyr::select(painel, dplyr::all_of(cont)), na.rm = TRUE)
  soma_estr <- rowSums(dplyr::select(painel, dplyr::all_of(estr)), na.rm = TRUE)
  viol <- sum(soma_cont > soma_estr + 0.5, na.rm = TRUE)
  add("  4c) continentes <= estrangeiros: ", viol, " violação(ões)  (", ok(viol==0), ")",
      "  [Σcont=", sum(soma_cont), " ; Σestrangeiros=", sum(soma_estr), "]")
} else add("  4c) continentes/estrangeiros: colunas-fonte ausentes — pulado.")
# 4d) faixas de pena: soma 8 faixas (M+F) vs condenados com tempo de pena
faixas <- c("0_2","2_4","4_8","8_15","15_20","20_30","30_mais","sem_info")
pcols <- as.vector(outer(c("pena_masculino_","pena_feminino_"), paste0(faixas,"anos"), paste0))
pcols <- intersect(pcols, names(painel))
if (length(pcols)) add("  4d) faixas de pena presentes: ", length(pcols), "/16  (", ok(length(pcols)==16), ") — Σ presos por pena = ",
                       sum(rowSums(dplyr::select(painel, dplyr::all_of(pcols)), na.rm = TRUE)))

# ---- Grava relatório ---------------------------------------------------------
saida <- file.path(paths$out_aud, "validacao_prisional.md")
writeLines(linhas, saida)
add("\nRelatório salvo em ", saida)
