# =============================================================================
# 03b_prisional_derivadas.R — Colunas DERIVADAS do prisional (padrão Monitor SP)
# -----------------------------------------------------------------------------
# CONSOLIDA o que o Monitor de SP faz em DOIS scripts (depen.R, 1º sem +
# dados_sem2.R, 2º sem). Como nossa fonte é a Base Única (todos os ciclos num só
# arquivo, com a coluna Referência "AAAA/S"), os dois semestres são apenas um
# FILTRO sobre o mesmo arquivo — então fazemos tudo numa leitura só.
#
# Fonte: Base Única SISDEPEN, RS, cela física, 2017–2025 (mesmo recorte do 03).
#   1º semestre (perfil/capacidade), como depen.R:
#     - Regime (4.1): provisorios/sentenciado_{fechado,semiaberto,aberto}/internacao/tratamento × M/F
#                     = soma Justiça Estadual + Federal + Outros (fiel a SP).
#     - Pena (5.12): pena_{m,f}_{0_2,2_4,4_8,8_15,15_20,20_30,30_mais,sem_info}  ← BINNING DE SP.
#     - Pena remanescente (5.13): pena_remanescente_{m,f}_{0_4,4_8,8_15,15_20,20_30,30_50,50mais}.
#     - Filhos (5.10): mulheres/homens_presos_com_filhos_as = soma de 1..10 e "11 ou mais".
#     - Tipo penal (5.14): 6 grupos × M/F/Total (CORRIGIDO — ver nota abaixo).
#     - Continentes (5.8): continente_{america,asia,africa,europa,oceania}
#                          = rowSums das colunas 5.8 do continente × (M|F) (fiel a depen.R::nacionalidade).
#   Dois semestres (fluxo):
#     - Mortalidade (6.8): a soma anual por categoria só aparece quando os dois
#       semestres têm valor, ligados por ID nativo + ano. A soma dos registros
#       disponíveis fica separada; unidades só no 2º semestre ficam na auditoria.
#   2º semestre:
#     - Atendimento (6.6): atendimento_estabelecimento/externo/odonto (Consultas|Total).
#     - cela_gestantes (2.1, texto Sim/Não) e quantidade_lactantes (5.9).
#
# Tipo penal: RS mantém "outros" residual e as demais regras já adotadas.
# Os nomes de saída são compatíveis com a apresentação SP, mas a comparação
# dos grupos ainda depende de reconciliar as regras (docs/auditoria_tipo_penal_sp.md).
#
# Saída: data/processed/prisional_derivadas_rs.csv  (id, periodo, <derivadas + obitos + sem2>)
# Substitui o antigo par 03b (derivadas 1º sem) + 03c (mortalidade 2º sem).
# =============================================================================

source(here::here("scripts/rs/00_config.R"))
norm_txt <- function(x) stringi::stri_trans_general(stringr::str_squish(stringr::str_to_lower(x)), "Latin-ASCII")
if (!isTRUE(cfg$escolhas$prisional_semestre == 1L)) {
  stop("A camada prisional requer estoque do 1º semestre para casar as derivadas.")
}

# ---- leitura única da Base Única ---------------------------------------------
arq <- arquivo_baseunica()
message("Base Única: ", basename(arq))
# guess_max = Inf: as colunas ESPARSAS (ex.: 5.8 nacionalidade por país, preenchidas em
# pouquíssimos estabelecimentos) ficam vazias nos primeiros milhares de registros nacionais;
# com guess_max baixo o readxl as adivinha como LÓGICAS e os valores reais (RS) viram NA —
# zerando os continentes. Um guess_max grande (readxl limita ao nº real de linhas) garante
# o tipo numérico correto. Evitamos Inf (algumas versões do readxl avisam).
df_full <- readxl::read_excel(arq, sheet = 1, guess_max = 1000000L)

# filtra UF + recorte cela física + anos, para UM semestre (mesmo recorte do 03)
prep_sem <- function(s) {
  ref_alvo <- paste0(cfg$anos_prisional, "/", s)
  d <- df_full |>
    dplyr::mutate(UF = toupper(.data[["UF"]]), ref = as.character(.data[["Referência"]])) |>
    dplyr::filter(UF == cfg$uf, ref %in% ref_alvo)
  if (identical(cfg$escolhas$prisional_recorte, "cela_fisica")) {
    nome_norm <- norm_txt(d[["Nome do Estabelecimento"]])
    d <- dplyr::filter(d,
      norm_txt(.data[["Tipo de Recolhimento"]]) == "cela fisica",
      !stringr::str_detect(nome_norm, "domiciliar|monitoramento eletronico|monitoracao eletronica"))
  }
  if (length(setdiff(ref_alvo, d$ref))) {
    stop("Ciclo sem registros no recorte: ", paste(setdiff(ref_alvo, d$ref), collapse = ", "))
  }
  if (any(is.na(d$ID) | trimws(as.character(d$ID)) == "") ||
      anyDuplicated(d[c("ID", "ref")])) {
    stop("ID SISDEPEN ausente ou repetido dentro do ciclo.")
  }
  d |> dplyr::mutate(
    ano = as.integer(stringr::str_extract(ref, "^\\d{4}")),
    periodo = as.character(ano),
    id = paste(`Nome do Estabelecimento`, UF, ano, sep = "-"),
    chave_ciclo = paste(UF, ID, ano, sep = "-"))
}
df1_bruto <- prep_sem(1L)  # universo de estoque
df2 <- prep_sem(2L)
# Preserva o tratamento anterior somente nas derivadas de estoque de múltiplos
# campos. Mortalidade, consultas e campos brutos mantêm os vazios da fonte.
df1 <- df1_bruto |>
  dplyr::mutate(dplyr::across(where(is.numeric), ~ tidyr::replace_na(.x, 0)))

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

# ---- População e Capacidade TOTAIS (lotação = população / capacidade) --------
# populacao_total: total de pessoas (4.1 | Total, reportado pelo SISDEPEN).
# capacidade_total: vagas (1.3 Capacidade | Masculino | Total + | Feminino | Total).
col_pop_tot <- "4.1 População prisional | Total"
der$populacao_total <- if (col_pop_tot %in% names(df1)) df1[[col_pop_tot]] else NA_real_
cap_m <- "1.3 Capacidade do estabelecimento | Masculino | Total"
cap_f <- "1.3 Capacidade do estabelecimento | Feminino | Total"
der$capacidade_total <- (if (cap_m %in% names(df1)) df1[[cap_m]] else 0) +
                        (if (cap_f %in% names(df1)) df1[[cap_f]] else 0)

# Total de médicos: soma das 4 categorias de médico (3.1 Servidores | Médicos ... | Total)
# = clínicos gerais + ginecologistas + psiquiatras + outras especialidades. O padrão pega
# as 4 colunas "| Total" (o traço varia "-"/"–", mas todas contêm "Médicos" e "| Total");
# não há agregado "Médicos | Total" no SISDEPEN, então não há dupla contagem. (Obs.: o
# depen.R de SP somava só 3, omitindo ginecologistas — aqui incluímos as 4.)
der$total_medicos <- s1(c("3.1", "Médicos", "| Total"), mínimo = 1L)
# Agravos transmissíveis (6.7): usar as colunas RAW por sexo já no painel
# ("6.7 … | HIV | Masculino/Feminino", idem Tuberculose/Hepatite/Sífilis). Sem derivadas de Total.

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
grupos_cp <- list(
  contra_pessoa = "Grupo: Crimes contra a pessoa",
  contra_patrimonio = "Grupo: Crimes contra o patrimônio",
  dignidade_sexual = "Grupo: Crimes contra a dignidade sexual",
  drogas = "Grupo: Drogas (Lei 6.368/76 e Lei 11.343/06)",
  desarmamento = "Grupo: Estatuto do Desarmamento")
for (g in names(grupos_cp)) for (TT in c("Masculino","Feminino","Total")) {
  der[[paste0("tipo_penal_", g, "_", tolower(TT))]] <-
    s1(c("5.14 Quantidade de incidências por tipo penal", grupos_cp[[g]], paste0(" | ", TT)), mínimo = 1L)
}
# OUTROS = residual: total geral (5.14 | sexo) − soma dos 5 grupos nomeados (sem dupla contagem)
for (TT in c("Masculino","Feminino","Total")) {
  somag <- Reduce(`+`, lapply(names(grupos_cp), function(g) der[[paste0("tipo_penal_", g, "_", tolower(TT))]]))
  alvo <- paste0("5.14 Quantidade de incidências por tipo penal | ", TT)
  total_geral <- if (alvo %in% names(df1)) df1[[alvo]] else { message("⚠ total geral 5.14 ausente p/ ", TT); NULL }
  if (!is.null(total_geral)) der[[paste0("tipo_penal_outros_", tolower(TT))]] <- pmax(total_geral - somag, 0)
}
if (is.null(der[["tipo_penal_outros_total"]]) && !is.null(der[["tipo_penal_outros_masculino"]]))
  der[["tipo_penal_outros_total"]] <- der[["tipo_penal_outros_masculino"]] + der[["tipo_penal_outros_feminino"]]

# ---- Continentes (5.8): origem dos presos ESTRANGEIROS por continente ---------
# = rowSums de todas as colunas 5.8 que contêm o nome do continente × (Masculino|Feminino),
# inclusive "Outros países do continente X". Brasileiros ficam em Brasileiro nato/naturalizado
# (fora); "Sem informação" não entra em continente. Fiel a depen.R::nacionalidade.
cont_sum <- function(d, continente) {
  nm <- names(d)
  cols <- nm[grepl("5.8", nm, fixed = TRUE) & grepl(continente, nm, fixed = TRUE) &
             (grepl("Masculino", nm, fixed = TRUE) | grepl("Feminino", nm, fixed = TRUE))]
  if (length(cols) == 0) { message("⚠ 5.8 sem colunas para ", continente, " — continente = 0"); return(rep(0, nrow(d))) }
  rowSums(dplyr::select(d, dplyr::all_of(cols)), na.rm = TRUE)
}
der$continente_america <- cont_sum(df1, "América")
der$continente_asia    <- cont_sum(df1, "Ásia")
der$continente_africa  <- cont_sum(df1, "África")
der$continente_europa  <- cont_sum(df1, "Europa")
der$continente_oceania <- cont_sum(df1, "Oceania")
# Brasileiros natos (total = Masculino + Feminino), para o painel de nacionalidade ao lado
# dos continente_*. ("Brasileiro nato" não casa com "naturalizado"; só há M e F, sem | Total.)
der$brasileiro_nato <- s1(c("5.8", "Brasileiro nato"), mínimo = 2L)

# ---- Mortalidade registrada (6.8): agrega os dois semestres por ID SISDEPEN ---
tipos_ob <- list(saude = "Óbitos naturais", criminais = "Óbitos criminais",
                 suicidio = "Óbitos suicídios", acidentais = "Óbitos acidentais",
                 desconhecida = "Óbitos com causa desconhecida")
obitos_frame <- function(d) {
  nm <- names(d); out <- tibble::tibble(chave_ciclo = d$chave_ciclo)
  for (tk in names(tipos_ob)) for (sx in c("masculino","feminino","total")) {
    Sx <- c(masculino="Masculino", feminino="Feminino", total="Total")[[sx]]
    col <- nm[grepl("6.8 Mortalidade", nm, fixed = TRUE) &
              grepl(tipos_ob[[tk]], nm, fixed = TRUE) & endsWith(nm, paste0("| ", Sx))]
    if (length(col) != 1) stop("Coluna 6.8 não única: ", tipos_ob[[tk]], " | ", Sx, " (", length(col), ")")
    out[[paste0("obitos_", tk, "_", sx)]] <- d[[col]]
  }
  out
}
soma_registrada <- function(a, b) {
  ifelse(is.na(a) & is.na(b), NA_real_,
         tidyr::replace_na(a, 0) + tidyr::replace_na(b, 0))
}
m1 <- obitos_frame(df1_bruto)
m2 <- obitos_frame(df2)
ob_cols <- setdiff(names(m1), "chave_ciclo")
ob_tot_cols <- grep("_total$", ob_cols, value = TRUE)
informado <- function(m) rowSums(!is.na(m[ob_tot_cols])) > 0L
completo <- function(m) rowSums(!is.na(m[ob_tot_cols])) == length(ob_tot_cols)
m1$mortalidade_sem1_informada <- informado(m1)
m1$mortalidade_sem1_campos_completos <- completo(m1)
m2$mortalidade_sem2_informada <- informado(m2)
m2$mortalidade_sem2_campos_completos <- completo(m2)
m2$sem2_registro <- TRUE
mort <- dplyr::left_join(m1, dplyr::rename_with(m2, ~paste0(.x, "_s2"), dplyr::all_of(ob_cols)),
                         by = "chave_ciclo", relationship = "one-to-one")
reg <- lapply(ob_tot_cols, function(c)
  soma_registrada(mort[[c]], mort[[paste0(c, "_s2")]]))
reg <- do.call(cbind, reg)
mort$obitos_registrados <- ifelse(rowSums(!is.na(reg)) > 0L, rowSums(reg, na.rm = TRUE), NA_real_)
# A soma convencional propaga NA se faltar a categoria em um dos semestres.
for (c in ob_cols) mort[[c]] <- mort[[c]] + mort[[paste0(c, "_s2")]]
mort <- mort |>
  dplyr::select(chave_ciclo, dplyr::all_of(ob_cols), obitos_registrados, sem2_registro,
                dplyr::starts_with("mortalidade_sem")) |>
  dplyr::mutate(dplyr::across(c(sem2_registro, dplyr::starts_with("mortalidade_sem")),
                             ~ tidyr::replace_na(.x, FALSE)))

# ---- Colunas do 2º semestre: atendimento (6.6), gestantes (2.1), lactantes (5.9)
# 6.6 — Informações da área de saúde (total do período): 4 tipos de consulta (| Total).
# atendimento_estabelecimento/externo = consultas médicas; atendimento_psicologico;
# atendimento_odonto = consultas odontológicas. (SP só trazia médicas+odonto; incluímos psicológicas.)
sem2 <- tibble::tibble(
  chave_ciclo = df2$chave_ciclo,
  atendimento_estabelecimento = col_unica(df2, c("6.6", "Consultas médicas realizadas no estabelecimento", "| Total")),
  atendimento_externo         = col_unica(df2, c("6.6", "Consultas médicas realizadas externamente", "| Total")),
  atendimento_psicologico     = col_unica(df2, c("6.6", "Consultas psicológicas", "| Total")),
  atendimento_odonto          = col_unica(df2, c("6.6", "Consultas odontológicas", "| Total")),
  cela_gestantes              = col_unica(df2, c("2.1", "dormitório para gestantes")),
  quantidade_lactantes        = col_unica(df2, c("5.9", "Quantidade de lactantes"))
)

# ---- Junta no universo de estoque (1º semestre), sem depender do nome --------
der$chave_ciclo <- df1$chave_ciclo
der <- der |>
  dplyr::left_join(mort, by = "chave_ciclo", relationship = "one-to-one") |>
  dplyr::left_join(sem2, by = "chave_ciclo", relationship = "one-to-one") |>
  dplyr::select(-chave_ciclo)

readr::write_csv(der, file.path(paths$processed, "prisional_derivadas_rs.csv"), na = "")
message("OK — prisional_derivadas_rs.csv (", nrow(der), " linhas, ", ncol(der)-2, " derivadas; ",
        "óbitos anuais quando observados ambos os ciclos; registros parciais separados).")
# Cobertura por ciclo, incluindo unidades que não entram no estoque anual.
aud <- dplyr::bind_rows(lapply(cfg$anos_prisional, function(a) {
  i1 <- df1$ano == a
  i2 <- df2$ano == a
  so2 <- i2 & !df2$chave_ciclo %in% df1$chave_ciclo
  no_painel <- der$periodo == as.character(a)
  tibble::tibble(
    periodo = a,
    estab = sum(i1),
    estab_sem2 = sum(i2),
    estab_so_sem1 = sum(i1 & !df1$chave_ciclo %in% df2$chave_ciclo),
    estab_so_sem2 = sum(so2),
    estab_sem1_mortalidade_informada = sum(i1 & m1$mortalidade_sem1_informada),
    estab_sem2_mortalidade_informada = sum(i2 & m2$mortalidade_sem2_informada),
    estab_sem1_mortalidade_campos_completos = sum(i1 & m1$mortalidade_sem1_campos_completos),
    estab_sem2_mortalidade_campos_completos = sum(i2 & m2$mortalidade_sem2_campos_completos),
    estab_mortalidade_anual_campos_completos = sum(no_painel &
      der$mortalidade_sem1_campos_completos & der$mortalidade_sem2_campos_completos),
    obitos_total = {
      x <- as.matrix(der[no_painel, ob_tot_cols])
      if (all(is.na(x))) NA_real_ else sum(x, na.rm = TRUE)
    },
    obitos_registrados_no_painel = sum(der$obitos_registrados[no_painel], na.rm = TRUE),
    obitos_sem1_registrados = sum(as.matrix(m1[i1, ob_tot_cols]), na.rm = TRUE),
    obitos_sem2_registrados = sum(as.matrix(m2[i2, ob_tot_cols]), na.rm = TRUE),
    obitos_registrados_fora_do_painel = sum(as.matrix(m2[so2, ob_tot_cols]), na.rm = TRUE)
  )
}))
readr::write_csv(aud, file.path(paths$out_aud, "prisional_mortalidade_cobertura.csv"))
print(aud)
