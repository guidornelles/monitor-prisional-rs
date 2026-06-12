# =============================================================================
# 03b_prisional_derivadas.R — Colunas DERIVADAS do prisional (padrão Monitor SP)
# -----------------------------------------------------------------------------
# Calcula as variáveis derivadas que o Base_Sisdepen de SP publica e que não estão
# no SISDEPEN bruto. Reproduz FIELMENTE as definições de SP onde elas são corretas, e
# CORRIGE onde o depen.R de SP tem bug (ver docs/auditoria_tipo_penal_sp.md). As somas
# são feitas por PADRÃO de nome de coluna (não por transcrição) — robusto e auditável.
#
# Fonte: Base Única SISDEPEN, RS, 1º semestre, cela física (mesmo recorte do 03).
# Derivadas calculadas:
#   - Regime (ocup): provisorios/sentenciado_fechado/semiaberto/aberto/internacao/tratamento × M/F
#                    = soma Justiça Estadual + Federal + Outros (fiel a SP).
#   - Pena (5.12):   pena_{m,f}_{0_4,1_8,8_15,15_20,20_30,30_50,50_mais,sem_info} (fiel a SP).
#   - Pena remanescente (5.13): pena_remanescente_{m,f}_{0_4,4_8,8_15,15_20,20_30,30_50,50mais}.
#   - Filhos (5.10): mulheres/homens_presos_com_filhos_as = soma de 1..10 e "11 ou mais".
#   - Tipo penal (5.14): 6 grupos × M/F/Total. CORRIGIDO:
#       * desarmamento = soma dos 5 tipos (SP somava só 1 — bug auditado).
#       * contra_patrimonio = AMPLO (13 subtipos do CP; decisão do pesquisador).
#       * outros = RESIDUAL (total 5.14 − 5 grupos nomeados) → partição sem dupla contagem.
#     ⚠ Diverge do output (bugado) de SP; documentado para levar à equipe de SP.
#
# Saída: data/processed/prisional_derivadas_rs.csv  (id, periodo, <derivadas>)
# =============================================================================

source(here::here("scripts/rs/00_config.R"))
norm_txt <- function(x) stringi::stri_trans_general(stringr::str_squish(stringr::str_to_lower(x)), "Latin-ASCII")

# ---- leitura + recorte (idêntico ao 03) --------------------------------------
arq <- arquivo_baseunica()
message("Base Única: ", basename(arq))
df <- suppressWarnings(readxl::read_excel(arq, sheet = 1, guess_max = 10000))
sem <- cfg$escolhas$prisional_semestre
ref_alvo <- paste0(cfg$anos, "/", sem)
df <- df |>
  dplyr::mutate(UF = toupper(.data[["UF"]]), ref = as.character(.data[["Referência"]])) |>
  dplyr::filter(UF == cfg$uf, ref %in% ref_alvo)
if ("Tipo de Recolhimento" %in% names(df)) {
  df <- dplyr::filter(df, norm_txt(.data[["Tipo de Recolhimento"]]) == "cela fisica")
}
df <- df |> dplyr::mutate(
  ano = as.integer(stringr::str_extract(ref, "^\\d{4}")),
  periodo = as.character(ano),
  id = paste(`Nome do Estabelecimento`, UF, ano, sep = "-"),
  dplyr::across(where(is.numeric), ~ ifelse(is.na(.), 0, .))
)

nomes <- names(df)
# soma, por linha, das colunas cujo nome contém TODOS os tokens (e exclui os de 'sem')
soma_cols <- function(tokens, sem_tokens = character(0), mínimo = 1L) {
  ok <- vapply(nomes, function(n)
    all(vapply(tokens, function(t) grepl(t, n, fixed = TRUE), logical(1))) &&
    !any(vapply(sem_tokens, function(t) grepl(t, n, fixed = TRUE), logical(1))),
    logical(1))
  cols <- nomes[ok]
  if (length(cols) < mínimo) stop("Padrão sem colunas suficientes (", length(cols), "<", mínimo, "): ",
                                  paste(tokens, collapse = " + "))
  rowSums(dplyr::select(df, dplyr::all_of(cols)))
}

der <- tibble::tibble(id = df$id, periodo = df$periodo)

# ---- Regime (4.1): soma Estadual + Federal + Outros, por regime × sexo -------
regimes <- list(
  provisorios = "Presos provisórios (sem condenação)",
  sentenciado_fechado = "Presos sentenciados - regime fechado",
  sentenciado_semiaberto = "Presos sentenciados - regime semiaberto",
  sentenciado_aberto = "Presos sentenciados - regime aberto",
  internacao = "Medida de segurança - internação",
  tratamento = "Medida de segurança - tratamento ambulatorial")
for (rk in names(regimes)) for (sx in c("masculino","feminino")) {
  Sx <- if (sx=="masculino") "Masculino" else "Feminino"
  der[[paste0(rk, "_", sx)]] <- soma_cols(
    c("4.1 População prisional", regimes[[rk]], "Just", Sx), mínimo = 3L)
}

# ---- Pena (5.12) e pena remanescente (5.13): faixas -> buckets ---------------
f6m  <- "Até 6 meses (inclusive)"; f1a <- "Mais de 6 meses até 1 ano (inclusive)"
f2a  <- "Mais de 1 ano até 2 anos (inclusive)"; f4a <- "Mais de 2 até 4 anos (inclusive)"
f8a  <- "Mais de 4 até 8 anos (inclusive)"; f15 <- "Mais de 8 até 15 anos (inclusive)"
f20  <- "Mais de 15 até 20 anos (inclusive)"; f30 <- "Mais de 20 até 30 anos (inclusive)"
f50  <- "Mais de 30 até 50 anos (inclusive)"; f100 <- "Mais de 50 até 100 anos (inclusive)"
fmais<- "Mais de 100 anos"; fsi <- "Número de pessoas sem informação"
add_faixa <- function(sec, faixa, Sx) soma_cols(c(sec, paste0("| ", faixa, " | "), Sx), mínimo = 1L)
for (sx in c("masculino","feminino")) {
  Sx <- if (sx=="masculino") "Masculino" else "Feminino"; S <- substr(sx,1,1)
  pre <- "5.12 Quantidade de pessoas privadas de liberdade por tempo total de penas"
  der[[paste0("pena_",sx,"_0_4anos")]]   <- add_faixa(pre,f6m,Sx)+add_faixa(pre,f1a,Sx)+add_faixa(pre,f2a,Sx)+add_faixa(pre,f4a,Sx)
  der[[paste0("pena_",sx,"_1_8anos")]]   <- add_faixa(pre,f8a,Sx)
  der[[paste0("pena_",sx,"_8_15anos")]]  <- add_faixa(pre,f15,Sx)
  der[[paste0("pena_",sx,"_15_20anos")]] <- add_faixa(pre,f20,Sx)
  der[[paste0("pena_",sx,"_20_30anos")]] <- add_faixa(pre,f30,Sx)
  der[[paste0("pena_",sx,"_30_50anos")]] <- add_faixa(pre,f50,Sx)
  der[[paste0("pena_",sx,"_50_maisanos")]] <- add_faixa(pre,f100,Sx)+add_faixa(pre,fmais,Sx)
  der[[paste0("pena_",sx,"_sem_info")]]  <- add_faixa(pre,fsi,Sx)
  prr <- "5.13 Quantidade de pessoas privadas de liberdade por tempo de pena remanescente"
  suf <- if (sx=="masculino") "masculino" else "feminino"
  der[[paste0("pena_remanescente_",suf,"_0_4anos")]]   <- add_faixa(prr,f6m,Sx)+add_faixa(prr,f1a,Sx)+add_faixa(prr,f2a,Sx)+add_faixa(prr,f4a,Sx)
  der[[paste0("pena_remanescente_",suf,"_4_8anos")]]   <- add_faixa(prr,f8a,Sx)
  der[[paste0("pena_remanescente_",suf,"_8_15anos")]]  <- add_faixa(prr,f15,Sx)
  der[[paste0("pena_remanescente_",suf,"_15_20anos")]] <- add_faixa(prr,f20,Sx)
  der[[paste0("pena_remanescente_",suf,"_20_30anos")]] <- add_faixa(prr,f30,Sx)
  der[[paste0("pena_remanescente_",suf,"_30_50anos")]] <- add_faixa(prr,f50,Sx)
  der[[paste0("pena_remanescente_",suf,"_50maisanos")]]<- add_faixa(prr,f100,Sx)+add_faixa(prr,fmais,Sx)
}

# ---- Filhos (5.10): soma de 1..10 e "11 ou mais" (exclui Sem filhos/Sem info) -
filhos <- function(Sx) Reduce(`+`, lapply(c(as.character(1:10), "11 ou mais"),
  function(n) soma_cols(c("5.10 Número de filhos/as", paste0("| ", n, " | "), Sx), mínimo = 1L)))
der$mulheres_presas_com_filhos_as <- filhos("Feminino")
der$homens_presos_com_filhos_as   <- filhos("Masculino")

# ---- Tipo penal (5.14): 6 grupos × M/F/Total (CORRIGIDO) ---------------------
grupos_cp <- list(
  contra_pessoa = "Grupo: Crimes contra a pessoa",
  contra_patrimonio = "Grupo: Crimes contra o patrimônio",   # AMPLO: todos os 13 subtipos do grupo
  dignidade_sexual = "Grupo: Crimes contra a dignidade sexual",
  drogas = "Grupo: Drogas (Lei 6.368/76 e Lei 11.343/06)",
  desarmamento = "Grupo: Estatuto do Desarmamento")
# soma de todas as colunas-folha do grupo, por sexo/total
for (g in names(grupos_cp)) for (TT in c("Masculino","Feminino","Total")) {
  der[[paste0("tipo_penal_", g, "_", tolower(TT))]] <-
    soma_cols(c("5.14 Quantidade de incidências por tipo penal", grupos_cp[[g]],
                paste0(" | ", TT)), mínimo = 1L)
}
# OUTROS = residual: total geral (5.14 | sexo) − soma dos 5 grupos nomeados
grand <- function(TT) {
  alvo <- paste0("5.14 Quantidade de incidências por tipo penal | ", TT)
  if (!alvo %in% nomes) stop("Total geral não encontrado: ", alvo)
  df[[alvo]]
}
for (TT in c("Masculino","Feminino","Total")) {
  somag <- Reduce(`+`, lapply(names(grupos_cp), function(g) der[[paste0("tipo_penal_", g, "_", tolower(TT))]]))
  total_geral <- tryCatch(grand(TT), error = function(e) { message("⚠ ", conditionMessage(e),
                          " — outros_", tolower(TT), " via M+F."); NULL })
  if (!is.null(total_geral)) der[[paste0("tipo_penal_outros_", tolower(TT))]] <- pmax(total_geral - somag, 0)
}
if (is.null(der[["tipo_penal_outros_total"]]) && !is.null(der[["tipo_penal_outros_masculino"]]))
  der[["tipo_penal_outros_total"]] <- der[["tipo_penal_outros_masculino"]] + der[["tipo_penal_outros_feminino"]]

readr::write_csv(der, file.path(paths$processed, "prisional_derivadas_rs.csv"))
message("OK — prisional_derivadas_rs.csv (", nrow(der), " linhas, ", ncol(der)-2, " derivadas).")
print(utils::head(der[, 1:8]))
