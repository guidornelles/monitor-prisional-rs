# =============================================================================
# 03b_prisional_derivadas.R — Colunas DERIVADAS do prisional (padrão Monitor SP)
# -----------------------------------------------------------------------------
# CONSOLIDA o que o Monitor de SP faz em DOIS scripts (depen.R, 1º sem +
# dados_sem2.R, 2º sem). Como nossa fonte é a Base Única (todos os ciclos num só
# arquivo, com a coluna Referência "AAAA/S"), os dois semestres são apenas um
# FILTRO sobre o mesmo arquivo — então fazemos tudo numa leitura só.
#
# Fonte: Base Única SISDEPEN, RS, cela física (mesmo recorte do 03).
#   1º semestre (perfil/capacidade), como depen.R:
#     - Regime (4.1): provisorios/sentenciado_{fechado,semiaberto,aberto}/internacao/tratamento × M/F
#                     = soma Justiça Estadual + Federal + Outros (fiel a SP).
#     - Pena (5.12): pena_{m,f}_{0_2,2_4,4_8,8_15,15_20,20_30,30_mais,sem_info}  ← BINNING DE SP.
#     - Pena remanescente (5.13): pena_remanescente_{m,f}_{0_4,4_8,8_15,15_20,20_30,30_50,50mais}.
#     - Filhos (5.10): mulheres/homens_presos_com_filhos_as = soma de 1..10 e "11 ou mais".
#     - Tipo penal (5.14): 6 grupos × M/F/Total (CORRIGIDO — ver nota abaixo).
#     - Continentes (5.8): continente_{america,asia,africa,europa,oceania}
#                          = rowSums das colunas 5.8 do continente × (M|F) (fiel a depen.R::nacionalidade).
#   2º semestre, como dados_sem2.R:
#     - Mortalidade (6.8): obitos_{saude,criminais,suicidio,acidentais,desconhecida}_{m,f,total}
#       = óbitos do 1º sem + óbitos do 2º sem  (ANUAL — era o erro: a versão antiga pegava só o 2º).
#     - Atendimento (6.6): atendimento_estabelecimento/externo/odonto (Consultas|Total).
#     - cela_gestantes (2.1, texto Sim/Não) e quantidade_lactantes (5.9).
#
# ⚠ Tipo penal: a PoC DIVERGE de propósito do depen.R de SP, que tem bugs
#   (contra_pessoa_total soma por engano um termo de patrimônio; desarmamento é
#   dupla-contado dentro de "outros"). Mantemos a versão CORRIGIDA (outros = residual)
#   e levaremos o ponto à equipe de SP. Ver docs/auditoria_tipo_penal_sp.md.
#
# Saída: data/processed/prisional_derivadas_rs.csv  (id, periodo, <derivadas + obitos + sem2>)
# Substitui o antigo par 03b (derivadas 1º sem) + 03c (mortalidade 2º sem).
# =============================================================================

source(here::here("scripts/rs/00_config.R"))
norm_txt <- function(x) stringi::stri_trans_general(stringr::str_squish(stringr::str_to_lower(x)), "Latin-ASCII")

# ---- leitura única da Base Única ---------------------------------------------
arq <- arquivo_baseunica()
message("Base Única: ", basename(arq))
df_full <- suppressWarnings(readxl::read_excel(arq, sheet = 1, guess_max = 10000))

# filtra UF + recorte cela física + anos, para UM semestre (mesmo recorte do 03)
prep_sem <- function(s) {
  ref_alvo <- paste0(cfg$anos, "/", s)
  d <- df_full |>
    dplyr::mutate(UF = toupper(.data[["UF"]]), ref = as.character(.data[["Referência"]])) |>
    dplyr::filter(UF == cfg$uf, ref %in% ref_alvo)
  if (identical(cfg$escolhas$prisional_recorte, "cela_fisica") &&
      "Tipo de Recolhimento" %in% names(d)) {
    nome_norm <- norm_txt(d[["Nome do Estabelecimento"]])
    d <- dplyr::filter(d,
      norm_txt(.data[["Tipo de Recolhimento"]]) == "cela fisica",
      !stringr::str_detect(nome_norm, "domiciliar|monitoramento eletronico|monitoracao eletronica"))
  }
  d |> dplyr::mutate(
    ano = as.integer(stringr::str_extract(ref, "^\\d{4}")),
    periodo = as.character(ano),
    id = paste(`Nome do Estabelecimento`, UF, ano, sep = "-"),
    dplyr::across(where(is.numeric), ~ ifelse(is.na(.), 0, .)))
}
df1 <- prep_sem(1L)   # perfil/capacidade/estrutura (universo da camada, como depen.R)
df2 <- prep_sem(2L)   # 2º sem: mortalidade, atendimento, gestantes, lactantes

# ---- helpers de soma por PADRÃO de nome (sobre um data frame) -----------------
# fábrica: devolve uma 'soma_cols' ligada a um data frame específico (df1 ou df2)
somador <- function(d) {
  nomes <- names(d)
  function(tokens, sem_tokens = character(0), mínimo = 1L) {
    ok <- vapply(nomes, function(n)
      all(vapply(tokens, function(t) grepl(t, n, fixed = TRUE), logical(1))) &&
      !any(vapply(sem_tokens, function(t) grepl(t, n, fixed = TRUE), logical(1))),
      logical(1))
    cols <- nomes[ok]
    if (length(cols) < mínimo) stop("Padrão sem colunas suficientes (", length(cols), "<", mínimo, "): ",
                                    paste(tokens, collapse = " + "))
    rowSums(dplyr::select(d, dplyr::all_of(cols)))
  }
}
# localiza UMA coluna única que contém todos os tokens (para campos avulsos)
col_unica <- function(d, tokens) {
  nm <- names(d)
  ok <- nm[vapply(nm, function(n) all(vapply(tokens, function(t) grepl(t, n, fixed = TRUE), logical(1))), logical(1))]
  if (length(ok) != 1) stop("Coluna não única para ", paste(tokens, collapse = " + "), " (", length(ok), ")")
  d[[ok]]
}

s1 <- somador(df1)
der <- tibble::tibble(id = df1$id, periodo = df1$periodo)

# ---- Regime (4.1): soma Estadual + Federal + Outros, por regime × sexo --------
regimes <- list(
  provisorios = "Presos provisórios (sem condenação)",
  sentenciado_fechado = "Presos sentenciados - regime fechado",
  sentenciado_semiaberto = "Presos sentenciados - regime semiaberto",
  sentenciado_aberto = "Presos sentenciados - regime aberto",
  internacao = "Medida de segurança - internação",
  tratamento = "Medida de segurança - tratamento ambulatorial")
for (rk in names(regimes)) for (sx in c("masculino","feminino")) {
  Sx <- if (sx=="masculino") "Masculino" else "Feminino"
  der[[paste0(rk, "_", sx)]] <- s1(c("4.1 População prisional", regimes[[rk]], "Just", Sx), mínimo = 3L)
}

# ---- Pena (5.12) e pena remanescente (5.13): faixas -> buckets ----------------
# Faixas nativas do SISDEPEN (5.12/5.13):
f6m  <- "Até 6 meses (inclusive)"; f1a <- "Mais de 6 meses até 1 ano (inclusive)"
f2a  <- "Mais de 1 ano até 2 anos (inclusive)"; f4a <- "Mais de 2 até 4 anos (inclusive)"
f8a  <- "Mais de 4 até 8 anos (inclusive)"; f15 <- "Mais de 8 até 15 anos (inclusive)"
f20  <- "Mais de 15 até 20 anos (inclusive)"; f30 <- "Mais de 20 até 30 anos (inclusive)"
f50  <- "Mais de 30 até 50 anos (inclusive)"; f100 <- "Mais de 50 até 100 anos (inclusive)"
fmais<- "Mais de 100 anos"; fsi <- "Número de pessoas sem informação"
add_faixa <- function(sec, faixa, Sx) s1(c(sec, paste0("| ", faixa, " | "), Sx), mínimo = 1L)
for (sx in c("masculino","feminino")) {
  Sx <- if (sx=="masculino") "Masculino" else "Feminino"
  # PENA (5.12) — binning DE SP (depen.R): 0_2 / 2_4 / 4_8 / 8_15 / 15_20 / 20_30 / 30_mais / sem_info
  pre <- "5.12 Quantidade de pessoas privadas de liberdade por tempo total de penas"
  der[[paste0("pena_",sx,"_0_2anos")]]    <- add_faixa(pre,f6m,Sx)+add_faixa(pre,f1a,Sx)+add_faixa(pre,f2a,Sx)
  der[[paste0("pena_",sx,"_2_4anos")]]    <- add_faixa(pre,f4a,Sx)
  der[[paste0("pena_",sx,"_4_8anos")]]    <- add_faixa(pre,f8a,Sx)
  der[[paste0("pena_",sx,"_8_15anos")]]   <- add_faixa(pre,f15,Sx)
  der[[paste0("pena_",sx,"_15_20anos")]]  <- add_faixa(pre,f20,Sx)
  der[[paste0("pena_",sx,"_20_30anos")]]  <- add_faixa(pre,f30,Sx)
  der[[paste0("pena_",sx,"_30_maisanos")]]<- add_faixa(pre,f50,Sx)+add_faixa(pre,f100,Sx)+add_faixa(pre,fmais,Sx)
  der[[paste0("pena_",sx,"_sem_info")]]   <- add_faixa(pre,fsi,Sx)
  # PENA REMANESCENTE (5.13) — já idêntica a SP; não alterar
  prr <- "5.13 Quantidade de pessoas privadas de liberdade por tempo de pena remanescente"
  der[[paste0("pena_remanescente_",sx,"_0_4anos")]]   <- add_faixa(prr,f6m,Sx)+add_faixa(prr,f1a,Sx)+add_faixa(prr,f2a,Sx)+add_faixa(prr,f4a,Sx)
  der[[paste0("pena_remanescente_",sx,"_4_8anos")]]   <- add_faixa(prr,f8a,Sx)
  der[[paste0("pena_remanescente_",sx,"_8_15anos")]]  <- add_faixa(prr,f15,Sx)
  der[[paste0("pena_remanescente_",sx,"_15_20anos")]] <- add_faixa(prr,f20,Sx)
  der[[paste0("pena_remanescente_",sx,"_20_30anos")]] <- add_faixa(prr,f30,Sx)
  der[[paste0("pena_remanescente_",sx,"_30_50anos")]] <- add_faixa(prr,f50,Sx)
  der[[paste0("pena_remanescente_",sx,"_50maisanos")]]<- add_faixa(prr,f100,Sx)+add_faixa(prr,fmais,Sx)
}

# ---- Filhos (5.10): soma de 1..10 e "11 ou mais" -----------------------------
filhos <- function(Sx) Reduce(`+`, lapply(c(as.character(1:10), "11 ou mais"),
  function(n) s1(c("5.10 Número de filhos/as", paste0("| ", n, " | "), Sx), mínimo = 1L)))
der$mulheres_presas_com_filhos_as <- filhos("Feminino")
der$homens_presos_com_filhos_as   <- filhos("Masculino")

# ---- Tipo penal (5.14): 6 grupos × M/F/Total (CORRIGIDO — diverge de SP) ------
grupos_cp