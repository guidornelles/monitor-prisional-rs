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
causas <- c(saude = "Óbitos naturais/ óbitos por motivos de saúde",
            criminais = "Óbitos criminais", suicidio = "Óbitos suicídios",
            acidentais = "Óbitos acidentais", desconhecida = "Óbitos com causa desconhecida")
sexos <- c("Masculino", "Feminino", "Total")
campos <- as.vector(outer(names(causas), tolower(sexos),
                          function(causa, sexo) paste("obitos", causa, sexo, sep = "_")))
campos_fonte <- as.vector(outer(unname(causas), sexos, function(causa, sexo) {
  paste("6.8 Mortalidade no Sistema Prisional (total do período)", causa, sexo, sep = " | ")
}))
ob_tot_cols <- campos[endsWith(campos, "_total")]
flags <- c("sem2_registro", "mortalidade_sem1_informada", "mortalidade_sem2_informada",
           "mortalidade_sem1_campos_completos", "mortalidade_sem2_campos_completos")
if (!all(c(campos, "obitos_registrados", flags) %in% names(painel))) {
  stop("Painel sem os 15 campos de óbitos, registros ou indicadores de cobertura.")
}

# Recalcula a partir dos campos originais dos dois ciclos, sem ler as derivadas
# do 03b. Mantém também as combinações só do 2º semestre para conferir a auditoria.
arq_fonte <- arquivo_baseunica()
cabecalho <- names(readxl::read_excel(arq_fonte, sheet = 1, n_max = 0L))
chaves <- c("UF", "ID", "Referência", "Nome do Estabelecimento", "Tipo de Recolhimento")
if (!all(c(chaves, campos_fonte) %in% cabecalho)) {
  stop("Base Única sem todas as chaves e campos do quesito 6.8.")
}
tipos <- rep("skip", length(cabecalho))
tipos[match(chaves, cabecalho)] <- "text"
tipos[match(campos_fonte, cabecalho)] <- "numeric"
referencias <- as.vector(outer(cfg$anos_prisional, 1:2, paste, sep = "/"))
origem <- readxl::read_excel(arq_fonte, sheet = 1, col_types = tipos) |>
  dplyr::filter(toupper(UF) == cfg$uf, .data[["Referência"]] %in% referencias)
if (identical(cfg$escolhas$prisional_recorte, "cela_fisica")) {
  norm <- function(x) stringi::stri_trans_general(stringr::str_squish(tolower(x)), "Latin-ASCII")
  origem <- origem |>
    dplyr::filter(norm(.data[["Tipo de Recolhimento"]]) == "cela fisica",
                  !grepl("domiciliar|monitoramento eletronico|monitoracao eletronica",
                         norm(.data[["Nome do Estabelecimento"]])))
}
chave_origem <- paste(origem$ID, origem[["Referência"]], sep = ":")
verifica("Identidade dos registros semestrais da fonte sem repetição", !anyDuplicated(chave_origem))
ix1 <- match(paste0(painel$ID, ":", painel$ano, "/1"), chave_origem)
ix2 <- match(paste0(painel$ID, ":", painel$ano, "/2"), chave_origem)
verifica("O painel cobre todas as chaves de estoque do primeiro semestre",
         !anyNA(ix1) && setequal(ix1, which(endsWith(origem[["Referência"]], "/1"))))
sem1 <- as.matrix(origem[ix1, campos_fonte])
sem2 <- as.matrix(origem[ix2, campos_fonte])
total_fonte <- match(ob_tot_cols, campos)
esperados <- replace(sem1, is.na(sem1), 0) + replace(sem2, is.na(sem2), 0)
for (j in seq_along(campos)) {
  verifica(paste("Soma por ID e ano com ausências a zero:", campos[[j]]),
           all(as.numeric(painel[[campos[[j]]]]) == esperados[, j]))
}
informados1 <- rowSums(!is.na(sem1[, total_fonte, drop = FALSE]))
informados2 <- rowSums(!is.na(sem2[, total_fonte, drop = FALSE]))
verifica("Cobertura do painel confere com os valores originais dos dois ciclos",
         all(painel$sem2_registro == !is.na(ix2)) &&
           all(painel$mortalidade_sem1_informada == (informados1 > 0L)) &&
           all(painel$mortalidade_sem2_informada == (informados2 > 0L)) &&
           all(painel$mortalidade_sem1_campos_completos == (informados1 == length(ob_tot_cols))) &&
           all(painel$mortalidade_sem2_campos_completos == (informados2 == length(ob_tot_cols))))
registrados <- ifelse(informados1 + informados2 > 0L,
                      rowSums(esperados[, total_fonte, drop = FALSE]), NA_real_)
verifica("Óbitos registrados por ID e ano preservam ausência dos dois blocos totais",
         identical(as.numeric(painel$obitos_registrados), registrados))

arq_cob <- file.path(paths$out_aud, "prisional_mortalidade_cobertura.csv")
if (!file.exists(arq_cob)) stop("Auditoria de cobertura de mortalidade não encontrada: rode 03b.")
mc <- readr::read_csv(arq_cob, show_col_types = FALSE)
verifica("Auditoria de mortalidade cobre os anos configurados",
         !anyDuplicated(mc$periodo) && setequal(mc$periodo, cfg$anos_prisional))
somar_fonte <- function(indices) {
  sum(as.matrix(origem[indices, campos_fonte[total_fonte]]), na.rm = TRUE)
}
for (i in seq_len(nrow(mc))) {
  r <- mc[i, ]
  no_painel <- painel$ano == r$periodo
  origem1 <- which(origem[["Referência"]] == paste0(r$periodo, "/1"))
  origem2 <- which(origem[["Referência"]] == paste0(r$periodo, "/2"))
  fora <- setdiff(origem2, ix2[no_painel])
  cobertura2 <- rowSums(!is.na(origem[origem2, campos_fonte[total_fonte]]))
  completo1 <- informados1[no_painel] == length(ob_tot_cols)
  completo2 <- informados2[no_painel] == length(ob_tot_cols)
  verifica(paste("Cobertura da auditoria confere com a fonte:", r$periodo),
           all(c(r$estab, r$estab_sem2, r$estab_so_sem1, r$estab_so_sem2,
                 r$estab_sem1_mortalidade_informada, r$estab_sem2_mortalidade_informada,
                 r$estab_sem1_mortalidade_campos_completos, r$estab_sem2_mortalidade_campos_completos,
                 r$estab_mortalidade_anual_campos_completos) ==
                 c(length(origem1), length(origem2), sum(is.na(ix2[no_painel])), length(fora),
                   sum(informados1[no_painel] > 0L), sum(cobertura2 > 0L),
                   sum(completo1), sum(cobertura2 == length(ob_tot_cols)), sum(completo1 & completo2))))
  semestres <- c(somar_fonte(origem1), somar_fonte(origem2))
  fora_total <- somar_fonte(fora)
  anual <- sum(as.matrix(painel[no_painel, ob_tot_cols]))
  verifica(paste("Reconciliação anual com os dois ciclos:", r$periodo),
           all(c(r$obitos_sem1_registrados, r$obitos_sem2_registrados,
                 r$obitos_registrados_fora_do_painel) == c(semestres, fora_total)) &&
             all(c(r$obitos_total, r$obitos_registrados_no_painel,
                   sum(painel$obitos_registrados[no_painel], na.rm = TRUE)) == anual) &&
             anual + fora_total == sum(semestres))
  add("  ", r$periodo, ": ", r$obitos_total, " óbitos registrados no painel; ",
      r$obitos_registrados_fora_do_painel, " em unidades só do 2º semestre. ",
      "Bloco com algum valor: ", r$estab_sem1_mortalidade_informada, "/", r$estab,
      " no 1º semestre e ", r$estab_sem2_mortalidade_informada, "/", r$estab_sem2,
      " no 2º. Todas as categorias nos dois semestres: ", r$estab_mortalidade_anual_campos_completos,
      "/", r$estab, ". Unidades só do 1º / só do 2º: ", r$estab_so_sem1, "/", r$estab_so_sem2, ".")
}
add("  > O cálculo trata campos vazios como zero. A cobertura parcial, sobretudo em 2018, limita a interpretação das somas de registros.")

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
