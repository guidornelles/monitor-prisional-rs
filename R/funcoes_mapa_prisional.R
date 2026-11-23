# Marcador do mapa na mesma tabela histórica do painel prisional.
# A janela é uma decisão do projeto: não usa a data do computador nem promove
# automaticamente o último ciclo encontrado na Base Única.
ano_referencia_mapa_prisional <- function(anos_configurados) {
  if (!is.numeric(anos_configurados) || !length(anos_configurados) ||
      anyNA(anos_configurados) || any(!is.finite(anos_configurados)) ||
      any(anos_configurados != floor(anos_configurados)) ||
      any(anos_configurados < 1) || anyDuplicated(anos_configurados)) {
    stop("Janela prisional inválida para definir o ano do mapa.")
  }
  as.integer(max(anos_configurados))
}

conferir_estoque_mapa_prisional <- function(painel, anos_configurados) {
  ano_mapa <- ano_referencia_mapa_prisional(anos_configurados)
  if (!is.data.frame(painel) || !all(c("ano", "ID", "Referência") %in% names(painel))) {
    stop("Mapa requer ano, ID SISDEPEN e Referência do estoque.")
  }
  if (!is.numeric(painel$ano) || anyNA(painel$ano) ||
      !setequal(painel$ano, anos_configurados)) {
    stop("Anos do estoque do mapa diferem da janela configurada; há ano ausente ou extra.")
  }
  ids <- as.character(painel$ID)
  if (anyNA(ids) || any(!nzchar(trimws(ids))) || anyDuplicated(painel[c("ID", "ano")])) {
    stop("ID do estoque do mapa ausente ou repetido no ano.")
  }
  if (!identical(as.character(painel[["Referência"]]), paste0(painel$ano, "/1"))) {
    stop("Mapa deve usar o estoque do primeiro semestre de cada ano.")
  }
  ano_mapa
}

adicionar_mapa_ultimo_ano_validado <- function(painel, anos_configurados) {
  ano_mapa <- conferir_estoque_mapa_prisional(painel, anos_configurados)
  campo <- "mapa_ultimo_ano_validado"
  if (campo %in% names(painel)) stop("Marcador do mapa já existe na tabela de entrada.")
  # Atribuição de uma única coluna ao final: preserva valores, ordem e classes
  # nativas de todos os campos históricos, inclusive os 551 campos atuais.
  painel[[campo]] <- painel$ano == ano_mapa
  painel
}

auditar_mapa_ultimo_ano_validado <- function(painel, anos_configurados, estoque_fonte) {
  ano_mapa <- conferir_estoque_mapa_prisional(painel, anos_configurados)
  if (!is.data.frame(estoque_fonte) ||
      !all(c("ID", "Referência") %in% names(estoque_fonte))) {
    stop("Auditoria do mapa requer IDs e referências independentes da Base Única.")
  }
  fonte_alvo <- estoque_fonte[!is.na(estoque_fonte[["Referência"]]) &
                               estoque_fonte[["Referência"]] == paste0(ano_mapa, "/1"), , drop = FALSE]
  ids_fonte <- as.character(fonte_alvo$ID)
  if (!length(ids_fonte) || anyNA(ids_fonte) || any(!nzchar(trimws(ids_fonte))) ||
      anyDuplicated(ids_fonte)) {
    stop("Estoque independente do último ano do mapa ausente ou com IDs inválidos.")
  }
  campo <- "mapa_ultimo_ano_validado"
  presente <- campo %in% names(painel)
  logico <- presente && is.logical(painel[[campo]]) && !anyNA(painel[[campo]])
  marcadas <- if (logico) which(painel[[campo]]) else integer()
  ids_marcados <- as.character(painel$ID[marcadas])
  checagens <- c(
    "Marcador do mapa presente como última coluna" = presente && tail(names(painel), 1L) == campo,
    "Marcador do mapa lógico e sem valores ausentes" = logico,
    "Mapa marca exclusivamente o maior ano da janela configurada" =
      logico && identical(painel[[campo]], painel$ano == ano_mapa),
    "Contagem do mapa coincide com o estoque independente do último ano" =
      logico && length(marcadas) == length(ids_fonte),
    "IDs do mapa coincidem com o estoque independente do primeiro semestre" =
      logico && !anyDuplicated(ids_marcados) && setequal(ids_marcados, ids_fonte)
  )
  list(ano = ano_mapa, estabelecimentos = length(marcadas), checagens = checagens)
}

alerta_ano_mapa_prisional <- function(referencias_fonte, anos_configurados) {
  ano_mapa <- ano_referencia_mapa_prisional(anos_configurados)
  refs <- unique(as.character(referencias_fonte))
  refs <- refs[!is.na(refs) & grepl("^[0-9]{4}/[12]$", refs)]
  anos_1 <- as.integer(substr(refs[endsWith(refs, "/1")], 1L, 4L))
  anos_2 <- as.integer(substr(refs[endsWith(refs, "/2")], 1L, 4L))
  posteriores <- sort(intersect(anos_1, anos_2))
  posteriores <- posteriores[posteriores > ano_mapa]
  if (!length(posteriores)) return(NULL)
  paste0("A Base Única fixada contém os dois ciclos de ano posterior à janela configurada: ",
         paste(posteriores, collapse = ", "), ". O mapa permanece em ", ano_mapa,
         "/1; revisar e validar a janela antes de ampliá-la.")
}
