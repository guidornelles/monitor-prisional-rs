# Regressões dos contratos de entrada, sem downloads e sem alterar bases reais.
# Executar a partir da raiz: Rscript scripts/tests/test_contexto.R
source(here::here("scripts/rs/00_config.R"))
source(here::here("R/funcoes_contexto.R"))
falha <- function(acao, mensagem) {
  erro <- tryCatch({ force(acao); NULL }, error = identity)
  stopifnot(inherits(erro, "error"), grepl(mensagem, conditionMessage(erro), fixed = TRUE))
}
diretorio <- tempfile("contratos_contexto_")
dir.create(diretorio)
file.create(file.path(diretorio, c("TDI_MUNICIPIOS_2024.xlsx", "TDI_MUNICIPIOS_2025.xlsx")))
stopifnot(basename(contexto_arquivo_tdi(diretorio, 2025L)) == "TDI_MUNICIPIOS_2025.xlsx")
falha(contexto_arquivo_tdi(diretorio, 2023L), "encontrados 0")
falha(contexto_arquivo_tdi(diretorio, 2024L, md5 = paste(rep("0", 32), collapse = "")),
      "hash do XLSX divergente")
dir.create(file.path(diretorio, "outra_edicao"))
file.create(file.path(diretorio, "outra_edicao", "TDI_MUNICIPIOS_2025.xlsx"))
falha(contexto_arquivo_tdi(diretorio, 2025L), "encontrados 2")

bruto <- tibble::tibble(`Ano (Código)` = 2023L, `Variável (Código)` = 37L,
                        `Unidade de Medida` = "Mil Reais", `Nível Territorial (Código)` = 6L,
                        `Município (Código)` = 4314902L, Valor = 1000)
arquivo <- file.path(diretorio, "sidra.csv")
ler <- function() contexto_ler_sidra(arquivo, 2023L, 37L, "Mil Reais", "pib")
readr::write_csv(bruto, arquivo)
stopifnot(ler()$pib == 1000)  # o leitor preserva mil reais, sem multiplicação oculta
for (campo in c("Ano (Código)", "Variável (Código)", "Unidade de Medida")) {
  alterado <- bruto
  alterado[[campo]] <- if (campo == "Unidade de Medida") "Reais" else 0L
  readr::write_csv(alterado, arquivo)
  falha(ler(), "referência divergente")
}
readr::write_csv(dplyr::bind_rows(bruto, bruto), arquivo)
falha(ler(), "repetido")
bruto$Valor <- "valor sem publicação"
readr::write_csv(bruto, arquivo)
falha(ler(), "valor ausente, inválido ou negativo")
falha(contexto_validar_chaves(tibble::tibble(id_municipio = c(1L, 2L)), ids = c(1L, 3L)),
      "universo municipal diferente")
destino <- file.path(diretorio, "aquisicao")
falha(contexto_obter_tdi(destino, 2025L, paste(rep("0", 32), collapse = ""),
                         paste(rep("0", 32), collapse = ""), snapshot = arquivo),
      "Snapshot do Inep não corresponde")
stopifnot(!file.exists(file.path(destino, "inep_tdi_2025_municipios.zip")))
message("OK — seleção entre anos, rejeição de ausência/ambiguidade, referência, unidade e chaves.")
