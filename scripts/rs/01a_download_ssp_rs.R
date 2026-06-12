# =============================================================================
# 01a_download_ssp_rs.R — Aquisição reprodutível dos dados criminais da SSP-RS
# -----------------------------------------------------------------------------
# Baixa as fontes da SSP-RS listadas (versões FIXADAS) em data/raw/ssp_rs/,
# descompacta os .zip e grava um MANIFESTO com hash de cada arquivo.
#
# Princípios de reprodutibilidade:
#  - VERSÕES FIXADAS (pinned): os URLs apontam para snapshots específicos. A SSP-RS
#    REVISA os dados ("atualizado em…"); fixar evita que os números mudem entre execuções.
#  - IDEMPOTENTE: se o arquivo já existe, não rebaixa (rode quantas vezes quiser).
#  - PROVENIÊNCIA: data/raw/ssp_rs/MANIFEST_ssp_rs.csv registra url, arquivo, bytes, md5, data.
#  - Os arquivos brutos NÃO vão para o Git (são grandes); este script os regenera.
#
# Uso (no R do usuário, com internet):
#   source("scripts/rs/01a_download_ssp_rs.R")
# Saída: data/raw/ssp_rs/<categoria>/...  +  MANIFEST_ssp_rs.csv
#
# Observação: a SSP-RS serve os arquivos em dois hosts (www e admin). O script
# tenta ambos. Se um URL quebrar (o portal reorganiza links), o erro é explícito
# e o arquivo deve ser baixado manualmente da página correspondente.
# =============================================================================

source(here::here("scripts/rs/00_config.R"))

dir_ssp <- here::here("data/raw/ssp_rs")
dir.create(dir_ssp, recursive = TRUE, showWarnings = FALSE)

hosts <- c("https://www.ssp.rs.gov.br", "https://admin.ssp.rs.gov.br")

fontes <- readr::read_csv(here::here("data/raw/ssp_rs_fontes.csv"), show_col_types = FALSE)

# Resolve um URL: se já for absoluto (http...), usa direto; senão tenta cada host.
urls_candidatos <- function(url) if (grepl("^https?://", url)) url else paste0(hosts, url)

# Baixa um arquivo tentando os hosts; devolve caminho local ou erro.
baixar <- function(url, destino) {
  if (file.exists(destino) && file.info(destino)$size > 0) {
    message("  (cache) ", basename(destino)); return(invisible(destino))
  }
  for (u in urls_candidatos(url)) {
    ok <- tryCatch({
      utils::download.file(u, destino, mode = "wb", quiet = TRUE)
      file.exists(destino) && file.info(destino)$size > 0
    }, error = function(e) FALSE)
    if (ok) { message("  baixado: ", basename(destino), " <- ", u); return(invisible(destino)) }
  }
  stop("FALHA ao baixar (todos os hosts): ", url,
       "\n  -> baixe manualmente da página da SSP-RS e coloque em ", dirname(destino))
}

# Descompacta de forma robusta a nomes internos não-UTF8 (latin-1 com acentos).
# O utils::unzip do R falha com "string multibyte inválida"; tentamos métodos
# que tratam os nomes como bytes: pacote 'zip', depois 'tar' do sistema (bsdtar),
# e por fim utils::unzip.
descompactar <- function(zipfile, exdir) {
  if (requireNamespace("zip", quietly = TRUE)) {
    if (isTRUE(tryCatch({ zip::unzip(zipfile, exdir = exdir); TRUE }, error = function(e) FALSE)))
      return(invisible("zip"))
  }
  if (isTRUE(tryCatch(system2("tar", c("-xf", shQuote(zipfile), "-C", shQuote(exdir)),
                              stdout = FALSE, stderr = FALSE) == 0L, error = function(e) FALSE)))
    return(invisible("tar"))
  if (isTRUE(tryCatch({ utils::unzip(zipfile, exdir = exdir, overwrite = TRUE); TRUE },
                      error = function(e) FALSE, warning = function(w) FALSE)))
    return(invisible("unzip"))
  warning("Não foi possível descompactar ", basename(zipfile),
          " — instale o pacote 'zip' (renv) ou extraia manualmente para ", exdir)
  invisible(NA)
}

manifesto <- list()
for (i in seq_len(nrow(fontes))) {
  f <- fontes[i, ]
  dir_cat <- file.path(dir_ssp, f$categoria, f$chave)
  dir.create(dir_cat, recursive = TRUE, showWarnings = FALSE)
  arq_baixado <- file.path(dir_cat, basename(sub("\\?.*$", "", f$url)))

  message("[", f$categoria, " / ", f$chave, "]")
  baixar(f$url, arq_baixado)

  # descompacta zip (idempotente: extrai sempre para a subpasta da chave)
  if (tolower(f$tipo) == "zip") {
    metodo <- descompactar(arq_baixado, dir_cat)
    if (!is.na(metodo)) message("  descompactado (", metodo, "): ", basename(arq_baixado))
  }

  manifesto[[i]] <- tibble::tibble(
    categoria = f$categoria, chave = f$chave, tipo = f$tipo, url = f$url,
    arquivo = arq_baixado, bytes = file.info(arq_baixado)$size,
    md5 = unname(tools::md5sum(arq_baixado)), data_download = as.character(Sys.Date())
  )
}

man <- dplyr::bind_rows(manifesto)
readr::write_csv(man, file.path(dir_ssp, "MANIFEST_ssp_rs.csv"))
message("\nOK — ", nrow(man), " fontes processadas. Manifesto: data/raw/ssp_rs/MANIFEST_ssp_rs.csv")
print(man[, c("categoria","chave","bytes","md5")], n = nrow(man))

# NOTA: a série Violência Contra a Mulher (VCM) está em OUTRA página
# (/indicadores-da-violencia-contra-a-mulher) — adicionar ao manifesto quando
# o respectivo código-fonte for fornecido. Para a PoC, estupro usa o microdado.
