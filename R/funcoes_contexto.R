# Contratos das fontes municipais de contexto. Não grava nem altera insumos.
# Ano, unidade e chave são verificados antes de qualquer junção.
contexto_validar_chaves <- function(dados, ids = NULL, n = NULL, fonte = "Fonte") {
  if (anyNA(dados$id_municipio) || anyDuplicated(dados$id_municipio))
    stop(fonte, ": código municipal ausente ou repetido.")
  if (!is.null(n) && nrow(dados) != n)
    stop(fonte, ": esperados ", n, " municípios; encontrados ", nrow(dados), ".")
  if (!is.null(ids) && !setequal(dados$id_municipio, ids))
    stop(fonte, ": universo municipal diferente do cadastro IBGE.")
  invisible(TRUE)
}

contexto_arquivo_tdi <- function(diretorio, ano, md5 = NULL) {
  arquivos <- list.files(diretorio, pattern = sprintf("^TDI_MUNICIPIOS_%d\\.xlsx$", ano),
                         recursive = TRUE, full.names = TRUE, ignore.case = TRUE)
  if (length(arquivos) != 1L)
    stop("Inep ", ano, ": esperado exatamente um TDI_MUNICIPIOS_", ano,
         ".xlsx; encontrados ", length(arquivos),
         ". Confira a aquisição em 01_download.R e as versões na pasta.")
  if (!is.null(md5) && !identical(unname(tools::md5sum(arquivos[[1]])), md5))
    stop("Inep: hash do XLSX divergente da edição fixada; preserve o arquivo e confira a origem.")
  arquivos[[1]]
}

contexto_obter_tdi <- function(diretorio, ano, md5_zip, md5_xlsx, snapshot = NULL) {
  # Reutiliza uma cópia oficial previamente arquivada somente se o hash conferir.
  # Nunca edita o conteúdo do ZIP/XLSX nem sobrescreve uma extração existente.
  dir.create(diretorio, recursive = TRUE, showWarnings = FALSE)
  destino <- file.path(diretorio, sprintf("inep_tdi_%d_municipios.zip", ano))
  if (!file.exists(destino)) {
    provisorio <- tempfile("inep_aquisicao_", tmpdir = diretorio, fileext = ".zip.part")
    on.exit(if (file.exists(provisorio)) unlink(provisorio), add = TRUE)
    if (!is.null(snapshot)) {
      if (!file.exists(snapshot) || !identical(unname(tools::md5sum(snapshot)), md5_zip))
        stop("Snapshot do Inep não corresponde à edição fixada.")
      if (!file.copy(snapshot, provisorio, overwrite = FALSE)) stop("Não foi possível copiar o ZIP do Inep.")
    } else {
      url <- sprintf(paste0("https://download.inep.gov.br/informacoes_estatisticas/",
                            "indicadores_educacionais/%d/TDI_%d_MUNICIPIOS.zip"), ano, ano)
      utils::download.file(url, provisorio, mode = "wb", quiet = TRUE)
    }
    if (!identical(unname(tools::md5sum(provisorio)), md5_zip))
      stop("Hash divergente no download do Inep; arquivo incompleto não será promovido.")
    if (!file.rename(provisorio, destino)) stop("Não foi possível concluir a aquisição do Inep.")
  }
  if (!identical(unname(tools::md5sum(destino)), md5_zip))
    stop("Hash divergente no ZIP do Inep. Confira a edição antes de atualizar a referência.")
  extraidos <- file.path(diretorio, "inep_distorcao")
  dir.create(extraidos, recursive = TRUE, showWarnings = FALSE)
  utils::unzip(destino, exdir = extraidos, overwrite = FALSE)
  contexto_arquivo_tdi(extraidos, ano, md5_xlsx)
}

contexto_ler_sidra <- function(arquivo, ano, variavel, unidade, nome_valor) {
  bruto <- readr::read_csv(arquivo, show_col_types = FALSE)
  esperados <- list("Ano (Código)" = as.character(ano),
                    "Variável (Código)" = as.character(variavel),
                    "Unidade de Medida" = unidade,
                    "Nível Territorial (Código)" = "6")
  obrigatorios <- c(names(esperados), "Município (Código)", "Valor")
  if (!all(obrigatorios %in% names(bruto))) stop(basename(arquivo), ": cabeçalho SIDRA incompleto.")
  for (campo in names(esperados)) {
    valores <- as.character(bruto[[campo]])
    if (!length(valores) || anyNA(valores) || any(valores != esperados[[campo]]))
      stop(basename(arquivo), ": referência divergente em ", campo, ".")
  }
  valor <- suppressWarnings(as.numeric(bruto$Valor))
  if (anyNA(valor) || any(!is.finite(valor)) || any(valor < 0))
    stop(basename(arquivo), ": valor ausente, inválido ou negativo.")
  resultado <- tibble::tibble(id_municipio = as.integer(bruto[["Município (Código)"]]))
  resultado[[nome_valor]] <- valor
  contexto_validar_chaves(resultado, fonte = basename(arquivo))
  resultado
}

contexto_ler_tdi <- function(arquivo, ano, uf) {
  # O cabeçalho-máquina fica na linha 9; a seleção descarta o rodapé do Inep.
  bruto <- suppressWarnings(readxl::read_excel(arquivo, skip = 8, .name_repair = "unique_quiet"))
  obrigatorios <- c("NU_ANO_CENSO", "SG_UF", "NO_CATEGORIA", "NO_DEPENDENCIA",
                    "CO_MUNICIPIO", "FUN_CAT_0")
  if (!all(obrigatorios %in% names(bruto))) stop("Inep: cabeçalho incompleto.")
  selecionado <- bruto |>
    dplyr::filter(SG_UF == uf, NO_CATEGORIA == "Total", NO_DEPENDENCIA == "Total")
  if (!nrow(selecionado) || anyNA(selecionado$NU_ANO_CENSO) ||
      any(selecionado$NU_ANO_CENSO != ano))
    stop("Inep: o conteúdo não corresponde ao ano ", ano, ".")
  texto <- trimws(as.character(selecionado$FUN_CAT_0))
  valor <- suppressWarnings(as.numeric(texto))
  if (any(is.na(valor) & !is.na(texto) & !texto %in% c("--", "-", "")) ||
      any(!is.finite(valor[!is.na(valor)])) || any(valor < 0 | valor > 100, na.rm = TRUE))
    stop("Inep: taxa inválida ou fora do intervalo 0–100.")
  resultado <- tibble::tibble(id_municipio = as.integer(selecionado$CO_MUNICIPIO),
                              distorcao_idade_serie_fund = valor)
  contexto_validar_chaves(resultado, fonte = "Inep Total/Total, ensino fundamental")
  resultado
}
