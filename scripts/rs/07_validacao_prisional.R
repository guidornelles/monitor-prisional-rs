# 07_validacao_prisional.R — Validação da versão candidata prisional do RS
# Depois de 03, 03b e 05, confere estoque, chaves, mortalidade e esquema.
# Falhas estruturais interrompem a geração da candidata; lacunas de fonte
# ficam no relatório de cobertura. Saída: outputs/auditoria/validacao_prisional.md.

source(here::here("scripts/rs/00_config.R"))

linhas <- character()
falhas <- character()
add <- function(...) {
  l <- paste0(...)
  message(l)
  linhas <<- c(linhas, l)
}
verifica <- function(nome, teste) {
  add("  ", nome, " (", if (isTRUE(teste)) "OK" else "FALHA", ")")
  if (!isTRUE(teste)) falhas <<- c(falhas, nome)
}

add("# Validação da camada prisional — ", format(Sys.time(), "%Y-%m-%d %H:%M"))

arq_painel <- file.path(paths$out_tab, "painel_prisional_estabelecimento.csv")
if (!file.exists(arq_painel)) stop("Rode 05 antes: não achei ", arq_painel)
painel <- readr::read_csv(arq_painel, show_col_types = FALSE)
if (!all(c("ano", "ID", "id") %in% names(painel)))
  stop("Painel sem ano, ID SISDEPEN ou id de apresentação.")

add("\n## 1. Janela, cobertura do estoque e identidade")
verifica("Anos do painel iguais à janela prisional configurada",
         !anyNA(painel$ano) && setequal(painel$ano, cfg$anos_prisional))
verifica("ID SISDEPEN não vazio e único no ano",
         all(!is.na(painel$ID) & trimws(as.character(painel$ID)) != "") &&
           !anyDuplicated(painel[c("ID", "ano")]))
verifica("ID de apresentação não vazio e único",
         all(!is.na(painel$id) & trimws(painel$id) != "") && !anyDuplicated(painel$id))

cob <- painel |> dplyr::count(ano, name = "estab") |> dplyr::arrange(ano)
# Conferência independente da planilha de referência, pelo ID nativo do 1º ciclo.
esperado <- stats::setNames(c(99L, 102L, 104L, 104L, 104L, 104L, 103L, 104L, 103L),
                            2017:2025)
if (basename(arquivo_baseunica()) == "sisdepen_baseunica_2025-2_25032026-163420.xlsx" &&
    identical(cfg$uf, "RS") && identical(cfg$escolhas$prisional_recorte, "cela_fisica")) {
  verifica("Cobertura confere com a extração independente da Base Única de referência",
           all(cob$estab == unname(esperado[as.character(cob$ano)])))
}
for (i in seq_len(nrow(cob))) add("  ", cob$ano[i], ": ", cob$estab[i], " estabelecimentos no recorte")
for (col in c("populacao_total", "capacidade_total")) {
  verifica(paste("Campo de estoque presente:", col), col %in% names(painel))
  if (col %in% names(painel))
    add("  ", col, ": ", sum(is.na(painel[[col]])), " sem valor; ",
        sum(painel[[col]] < 0, na.rm = TRUE), " negativos.")
}

add("\n## 2. Mortalidade registrada nos dois semestres")
ob_tot_cols <- grep("^obitos_.*_total$", names(painel), value = TRUE)
verifica("Cinco categorias de óbitos presentes", length(ob_tot_cols) == 5L)
flags <- c("mortalidade_sem1_informada", "mortalidade_sem2_informada")
verifica("Totais registrados e flags de cobertura disponíveis",
         all(c("obitos_registrados", flags) %in% names(painel)))
arq_cob <- file.path(paths$out_aud, "prisional_mortalidade_cobertura.csv")
if (!file.exists(arq_cob)) stop("Auditoria de cobertura de mortalidade não encontrada: rode 03b.")
mc <- readr::read_csv(arq_cob, show_col_types = FALSE)
verifica("Auditoria de mortalidade cobre os anos configurados",
         !anyDuplicated(mc$periodo) && setequal(mc$periodo, cfg$anos_prisional))
if (length(ob_tot_cols)) {
  ptotal <- vapply(mc$periodo, function(a) {
    x <- as.matrix(painel[painel$ano == a, ob_tot_cols])
    if (all(is.na(x))) NA_real_ else sum(x, na.rm = TRUE)
  }, numeric(1))
  verifica("Totais da camada prisional conferem com o processamento",
           isTRUE(all.equal(ptotal, mc$obitos_total)))
  sem_cobertura <- !(painel[[flags[1]]] & painel[[flags[2]]])
  verifica("Sem valor anual se um dos blocos semestrais não foi informado",
           all(is.na(as.matrix(painel[sem_cobertura, ob_tot_cols]))))
}
preg <- vapply(mc$periodo, function(a)
  sum(painel$obitos_registrados[painel$ano == a], na.rm = TRUE), numeric(1))
verifica("Óbitos registrados na camada conferem com o processamento",
         all(preg == mc$obitos_registrados_no_painel))
verifica("Reconciliação dos registros com ambos os ciclos, incluindo óbitos fora do estoque",
         all(mc$obitos_registrados_no_painel + mc$obitos_registrados_fora_do_painel ==
               mc$obitos_sem1_registrados + mc$obitos_sem2_registrados))
for (i in seq_len(nrow(mc))) {
  r <- mc[i, ]
  add("  ", r$periodo, ": ", r$obitos_total, " óbitos nas combinações com valor nos dois ciclos; ",
      r$obitos_registrados_no_painel, " óbitos registrados no painel (inclui cobertura parcial); ",
      r$obitos_registrados_fora_do_painel, " em unidades só do 2º semestre. ",
      "Bloco com algum valor: ", r$estab_sem1_mortalidade_informada, "/", r$estab,
      " no 1º semestre e ", r$estab_sem2_mortalidade_informada, "/", r$estab_sem2,
      " no 2º. Todas as categorias nos dois semestres: ", r$estab_mortalidade_anual_campos_completos,
      "/", r$estab, ". Unidades só do 1º / só do 2º: ", r$estab_so_sem1, "/", r$estab_so_sem2, ".")
}
add("  > Vazio do formulário não equivale a zero. A cobertura parcial, sobretudo em 2018, limita a interpretação dos totais por ano.")

add("\n## 3. Paridade de nomes com a base do Data Studio de SP")
arq_ds <- file.path(paths$raw, "bases_data_studio", "base_sisdepen - Sheet1.csv")
if (file.exists(arq_ds)) {
  ds_cols <- names(readr::read_csv(arq_ds, n_max = 0, show_col_types = FALSE))
  alvo <- c("provisorios_masculino", "sentenciado_fechado_masculino", "tratamento_feminino",
            "pena_masculino_0_2anos", "pena_masculino_2_4anos", "pena_masculino_30_maisanos",
            "pena_remanescente_masculino_0_4anos",
            "obitos_saude_total", "obitos_suicidio_total", "obitos_criminais_total",
            "obitos_acidentais_total", "obitos_desconhecida_total",
            "continente_america", "continente_asia", "continente_africa", "continente_europa", "continente_oceania",
            "atendimento_estabelecimento", "atendimento_externo", "atendimento_odonto",
            "cela_gestantes", "quantidade_lactantes",
            "mulheres_presas_com_filhos_as", "homens_presos_com_filhos_as",
            "tipo_penal_contra_pessoa_total", "tipo_penal_outros_total")
  alvo_ds <- intersect(alvo, ds_cols)
  faltam <- setdiff(alvo_ds, names(painel))
  verifica(paste0("Derivadas-alvo presentes: ", length(alvo_ds) - length(faltam), "/", length(alvo_ds)),
           !length(faltam))
  if (length(faltam)) add("  Faltam: ", paste(faltam, collapse = ", "))
} else add("  Exportação SP não encontrada; comparação de nomes não executada.")

add("\n## 4. Consistências e alertas de fonte")
difs <- 0L
comparaveis <- 0L
for (ct in ob_tot_cols) {
  cm <- sub("_total$", "_masculino", ct)
  cf <- sub("_total$", "_feminino", ct)
  if (all(c(cm, cf) %in% names(painel))) {
    dif <- painel[[ct]] - (painel[[cm]] + painel[[cf]])
    comparaveis <- comparaveis + sum(!is.na(dif))
    difs <- difs + sum(abs(dif) > 0.5, na.rm = TRUE)
  }
}
add("  Óbitos total vs M+F: ", difs, " divergência(s) em ", comparaveis,
    " combinações de categoria e unidade-ano com valores nos três campos.")
o <- grep("^tipo_penal_outros_", names(painel), value = TRUE)
verifica("Tipos penais residuais sem contagem negativa",
         length(o) == 3L && all(vapply(painel[o], function(v) all(v >= 0, na.rm = TRUE), logical(1))))
estr <- grep("5.8.*Estrangeiros - total.*\\| (Masculino|Feminino)$", names(painel), value = TRUE)
cont <- grep("^continente_", names(painel), value = TRUE)
if (length(estr) && length(cont)) {
  obs <- stats::complete.cases(painel[estr])
  soma_cont <- rowSums(painel[cont], na.rm = TRUE)
  soma_estr <- rowSums(painel[estr], na.rm = TRUE)
  add("  Soma por continentes acima do total informado de estrangeiros: ",
      sum(obs & (soma_cont > soma_estr), na.rm = TRUE), " em ", sum(obs), " linhas com total preenchido.")
}
suf <- c("0_2anos", "2_4anos", "4_8anos", "8_15anos", "15_20anos", "20_30anos", "30_maisanos", "sem_info")
pcols <- as.vector(outer(c("pena_masculino_", "pena_feminino_"), suf, paste0))
verifica("16 campos de faixas de pena disponíveis", all(pcols %in% names(painel)))
add("  > Presença de colunas não valida a distribuição de pena; consultar docs/problemas_dados.md.")

saida <- file.path(paths$out_aud, "validacao_prisional.md")
writeLines(enc2utf8(linhas), saida, useBytes = TRUE)
message("\nRelatório salvo em ", saida)
if (length(falhas)) stop("Falhas estruturais da camada prisional: ", paste(falhas, collapse = "; "))
