# =============================================================================
# 02c_mandados_sinesp.R — Série própria de mandados de prisão cumpridos
# Lê o snapshot VDE fixado em cfg$sinesp_dir (UF RS, abrangência Estadual,
# evento "Mandado de prisão cumprido", coluna total). O VDE conta pessoas
# com mandado cumprido. A série permanece separada dos registros de flagrante.
# O município de referência do VDE ainda requer confirmação.
#
# A soma municipal usa os meses informados. Com zero meses, apenas o campo de
# exibição recebe zero. O campo observado fica vazio e a cobertura fica em zero.
# O estado agrega os meses reconciliados, inclusive valores sem localização.
# Uma competência fica vazia quando as duas fontes carecem de valor.
# =============================================================================

source(here::here("scripts/rs/00_config.R"))

processar_mandados_sinesp <- function(cfg, paths) {
  anos <- sort(unique(as.integer(cfg$anos_criminal)))
  if (!identical(cfg$uf, "RS") || !length(anos) || anyNA(anos)) {
    stop("Mandados VDE: use UF RS e configure cfg$anos_criminal.", call. = FALSE)
  }
  if (is.null(cfg$sinesp_dir) || !dir.exists(cfg$sinesp_dir)) {
    stop("Mandados VDE: diretório do snapshot não encontrado (cfg$sinesp_dir).", call. = FALSE)
  }
  versao <- basename(normalizePath(cfg$sinesp_dir, winslash = "/"))
  fonte_ref <- if (is.null(cfg$sinesp_ref_ssp)) {
    here::here("outputs", "tabelas", paste0("auditoria_sinesp_", versao),
               "comparacao_atividade_rs.csv")
  } else {
    cfg$sinesp_ref_ssp
  }

  # Cabeçalhos e chaves usam transliteração sem substituir nomes por aproximação.
  chave <- function(x) {
    x <- stringi::stri_trans_general(x, "Latin-ASCII")
    x <- stringr::str_remove_all(stringr::str_to_upper(x), "['’]")
    stringr::str_squish(stringr::str_replace_all(x, "[^A-Z0-9]+", " "))
  }
  soma_observada <- function(x) if (all(is.na(x))) NA_real_ else sum(x, na.rm = TRUE)

  ibge <- readr::read_csv(
    file.path(paths$raw, "nacional", "ibge_municipios_regioes_rs.csv"),
    col_types = readr::cols_only(id_municipio = readr::col_integer(),
                                nome = readr::col_character(), sigla_uf = readr::col_character())
  ) |>
    dplyr::filter(sigla_uf == cfg$uf, !is.na(id_municipio)) |>
    dplyr::transmute(id_municipio, chave = chave(nome))
  stopifnot(nrow(ibge) == cfg$n_municipios, !anyNA(ibge$chave),
            all(nzchar(ibge$chave)), !anyDuplicated(ibge$chave),
            !anyDuplicated(ibge$id_municipio))

  manifesto <- readr::read_csv(
    file.path(cfg$sinesp_dir, "MANIFEST_sinesp_vde.csv"),
    col_types = readr::cols_only(ano_link = readr::col_integer(), arquivo = readr::col_character(),
                                bytes = readr::col_double(), sha256 = readr::col_character(),
                                url = readr::col_character(), retrieved_utc = readr::col_character())
  ) |>
    dplyr::filter(ano_link %in% anos) |>
    dplyr::arrange(ano_link)
  stopifnot(identical(manifesto$ano_link, anos), !anyNA(manifesto$sha256))
  proveniencia <- manifesto |>
    dplyr::transmute(ano = ano_link, versao, arquivo = basename(gsub("\\\\", "/", arquivo)),
                     url, coletado_em_utc = retrieved_utc, bytes, sha256)
  arqs <- file.path(cfg$sinesp_dir, proveniencia$arquivo)
  stopifnot(all(file.exists(arqs)), identical(as.numeric(file.size(arqs)), proveniencia$bytes))
  # Lê os bytes de cada XLSX: no Windows, file.access() pode reportar -1 mesmo
  # com o arquivo legível pelo processo (e digest(file=TRUE) usa esse teste).
  hashes <- vapply(arqs, function(p) {
    digest::digest(readBin(p, "raw", n = file.size(p)), algo = "sha256", serialize = FALSE)
  }, character(1), USE.NAMES = FALSE)
  if (!identical(tolower(hashes), tolower(proveniencia$sha256))) {
    stop("Mandados VDE: SHA-256 do arquivo diverge do manifesto.", call. = FALSE)
  }

  ler_ano <- function(arquivo, ano) {
    message("Mandados VDE — ", ano, " (", versao, ")")
    vde <- readxl::read_xlsx(
      arquivo, sheet = as.character(ano),
      col_types = c(rep("text", 3), "date", rep("text", 3),
                    rep("skip", 4), "text", "skip", "text")
    )
    esperado <- c("uf", "municipio", "evento", "data_referencia", "agente",
                  "arma", "faixa_etaria", "total", "abrangencia")
    if (!identical(names(vde), esperado)) {
      stop("Mandados VDE: esquema inesperado em ", basename(arquivo), ".", call. = FALSE)
    }
    vde <- vde |>
      dplyr::filter(uf == cfg$uf, abrangencia == "Estadual",
                    evento == "Mandado de prisão cumprido")
    if (anyNA(vde$data_referencia) ||
        any(as.integer(format(vde$data_referencia, "%Y", tz = "UTC")) != ano) ||
        any(!is.na(vde$agente) | !is.na(vde$arma) | !is.na(vde$faixa_etaria))) {
      stop("Mandados VDE: competência ou dimensão inesperada em ", ano, ".", call. = FALSE)
    }
    quant <- suppressWarnings(as.numeric(vde$total))
    if (any(!is.na(vde$total) & (is.na(quant) | !is.finite(quant) | quant < 0 | quant != floor(quant)))) {
      stop("Mandados VDE: valor não inteiro ou inválido em ", ano, ".", call. = FALSE)
    }
    tibble::tibble(ano, mes = as.integer(format(vde$data_referencia, "%m", tz = "UTC")),
                   municipio_vde = vde$municipio, chave = chave(vde$municipio),
                   mandados_observados = quant)
  }
  recorte <- purrr::map2_dfr(arqs, anos, ler_ano)
  sem_localizacao <- recorte |>
    dplyr::filter(is.na(chave) | chave %in% c("", "NAO INFORMADO")) |>
    dplyr::select(ano, mes, municipio_vde, mandados_observados)
  localizado <- recorte |>
    dplyr::filter(!is.na(chave), !chave %in% c("", "NAO INFORMADO")) |>
    dplyr::left_join(ibge, by = "chave")
  if (anyNA(localizado$id_municipio)) {
    stop("Mandados VDE: município sem código IBGE: ",
         paste(unique(localizado$municipio_vde[is.na(localizado$id_municipio)]), collapse = ", "),
         call. = FALSE)
  }
  stopifnot(!anyDuplicated(localizado[c("id_municipio", "ano", "mes")]),
            !anyDuplicated(sem_localizacao[c("ano", "mes")]))

  # A grade mensal conserva células sem valor para medir a cobertura.
  mensal <- tidyr::expand_grid(id_municipio = ibge$id_municipio, ano = anos, mes = 1:12) |>
    dplyr::left_join(dplyr::select(localizado, id_municipio, ano, mes, mandados_observados),
                     by = c("id_municipio", "ano", "mes"))
  municipal_anual <- mensal |>
    dplyr::group_by(id_municipio, ano) |>
    dplyr::summarise(meses_informados = sum(!is.na(mandados_observados)),
                     mandados_observados = soma_observada(mandados_observados), .groups = "drop") |>
    dplyr::mutate(mandados_cumpridos = dplyr::coalesce(mandados_observados, 0)) |>
    dplyr::select(id_municipio, ano, mandados_cumpridos, mandados_observados, meses_informados) |>
    dplyr::arrange(ano, id_municipio)

  # A referência SSP é o agregado estadual arquivado na auditoria anterior.
  # Reconciliar cada competência, incluindo a presença do valor nas duas fontes.
  if (!file.exists(fonte_ref)) {
    stop("Mandados VDE: falta referência mensal SSP para reconciliar este snapshot: ",
         fonte_ref, call. = FALSE)
  }
  referencia <- readr::read_csv(
    fonte_ref,
    col_types = readr::cols_only(ano = readr::col_integer(), mes = readr::col_integer(),
                                uf = readr::col_character(), evento = readr::col_character(),
                                valor_estadual = readr::col_double())
  ) |>
    dplyr::filter(uf == cfg$uf, evento == "Mandado de prisão cumprido", ano %in% anos) |>
    dplyr::transmute(ano, mes, mandados_estaduais_ssp_referencia = valor_estadual)
  stopifnot(!anyDuplicated(referencia[c("ano", "mes")]),
            all(referencia$mes %in% 1:12))
  recon_mensal <- mensal |>
    dplyr::group_by(ano, mes) |>
    dplyr::summarise(municipios_com_valor = sum(!is.na(mandados_observados)),
                     mandados_municipais_observados = soma_observada(mandados_observados), .groups = "drop") |>
    dplyr::left_join(dplyr::transmute(sem_localizacao, ano, mes,
                                      mandados_sem_localizacao_observados = mandados_observados),
                     by = c("ano", "mes")) |>
    dplyr::mutate(mandados_estaduais_vde = dplyr::if_else(
      is.na(mandados_municipais_observados) & is.na(mandados_sem_localizacao_observados),
      NA_real_, rowSums(cbind(mandados_municipais_observados, mandados_sem_localizacao_observados),
                        na.rm = TRUE))) |>
    dplyr::left_join(referencia, by = c("ano", "mes")) |>
    dplyr::mutate(diferenca = mandados_estaduais_vde - mandados_estaduais_ssp_referencia)
  erros <- recon_mensal |>
    dplyr::filter(is.na(mandados_estaduais_vde) != is.na(mandados_estaduais_ssp_referencia) |
                    (!is.na(diferenca) & diferenca != 0))
  if (nrow(erros) > 0L) {
    print(erros, n = Inf)
    stop("Mandados VDE: falha na reconciliação mensal. Nenhuma saída do módulo foi gravada.",
         call. = FALSE)
  }

  estadual_anual <- recon_mensal |>
    dplyr::group_by(ano) |>
    dplyr::summarise(mandados_cumpridos = soma_observada(mandados_estaduais_vde),
                     meses_informados = sum(!is.na(mandados_estaduais_vde)), .groups = "drop")
  cobertura <- municipal_anual |>
    dplyr::group_by(ano) |>
    dplyr::summarise(municipios_completos = sum(meses_informados == 12L),
                     municipios_parciais = sum(meses_informados > 0L & meses_informados < 12L),
                     municipios_sem_valor = sum(meses_informados == 0L),
                     mandados_municipios_completos = soma_observada(
                       mandados_observados[meses_informados == 12L]),
                     mandados_municipios_parciais_observados = sum(
                       mandados_observados[meses_informados > 0L & meses_informados < 12L]),
                     mandados_municipios_publicados = sum(mandados_cumpridos), .groups = "drop") |>
    dplyr::left_join(
      recon_mensal |>
        dplyr::group_by(ano) |>
        dplyr::summarise(meses_sem_localizacao_informados = sum(!is.na(mandados_sem_localizacao_observados)),
                         mandados_sem_localizacao_observados = soma_observada(mandados_sem_localizacao_observados),
                         meses_estaduais_informados = sum(!is.na(mandados_estaduais_vde)),
                         mandados_estaduais_vde = soma_observada(mandados_estaduais_vde),
                         mandados_estaduais_ssp_referencia = soma_observada(mandados_estaduais_ssp_referencia),
                         diferenca = soma_observada(diferenca), .groups = "drop"),
      by = "ano"
    )
  stopifnot(nrow(municipal_anual) == nrow(ibge) * length(anos),
            !anyDuplicated(municipal_anual[c("id_municipio", "ano")]),
            all(cobertura$mandados_municipios_publicados ==
                  dplyr::coalesce(cobertura$mandados_municipios_completos, 0) +
                  cobertura$mandados_municipios_parciais_observados),
            all(dplyr::coalesce(cobertura$mandados_estaduais_vde, 0) ==
                  cobertura$mandados_municipios_publicados +
                  dplyr::coalesce(cobertura$mandados_sem_localizacao_observados, 0)))

  readr::write_csv(municipal_anual, file.path(paths$processed, "mandados_rs_municipio_ano.csv"), na = "")
  readr::write_csv(estadual_anual, file.path(paths$processed, "mandados_rs_estadual_ano.csv"), na = "")
  readr::write_csv(recon_mensal, file.path(paths$out_aud, "mandados_sinesp_reconciliacao_mensal.csv"), na = "")
  readr::write_csv(cobertura, file.path(paths$out_aud, "mandados_sinesp_cobertura_anual.csv"), na = "")
  readr::write_csv(sem_localizacao, file.path(paths$out_aud, "mandados_sinesp_sem_localizacao.csv"), na = "")
  readr::write_csv(proveniencia, file.path(paths$out_aud, "mandados_sinesp_proveniencia.csv"), na = "")
  message("OK — mandados: ", sum(estadual_anual$meses_informados), " totais mensais reconciliados; ",
          nrow(municipal_anual), " pares município-ano na grade.")
}

processar_mandados_sinesp(cfg, paths)
