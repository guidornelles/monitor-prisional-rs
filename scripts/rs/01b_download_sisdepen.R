# =============================================================================
# 01b_download_sisdepen.R — Aquisição reprodutível do SISDEPEN (SENAPPEN)
# -----------------------------------------------------------------------------
# FONTE PRIMÁRIA: Base Única consolidada (todos os ciclos em arquivo único).
#   Baixada direto do SharePoint da SENAPPEN via link de compartilhamento + "&download=1"
#   (URL em cfg$sisdepen_baseunica_url; testado e funcional). Vantagens da Base Única
#   sobre os arquivos por ciclo estão em docs/decisoes_metodologicas.md (campo
#   "Tipo de Recolhimento" 100% preenchido em todos os anos, ID estável, esquema único).
#
# FALLBACK/VALIDAÇÃO: arquivos por ciclo (gov.br), baixados só se solicitado
#   (baixar_ciclos = TRUE) — servem para conferir a Base Única de forma independente.
#
# Reprodutibilidade: integridade conferida por md5 (cfg$sisdepen_baseunica_md5) +
# manifesto. Arquivos grandes (~70 MB) — NÃO vão para o Git.
#
# Uso (no R do usuário, com internet):  source("scripts/rs/01b_download_sisdepen.R")
# =============================================================================

source(here::here("scripts/rs/00_config.R"))

dir_sis <- here::here("data/raw/sisdepen"); dir.create(dir_sis, recursive = TRUE, showWarnings = FALSE)
baixar_ciclos <- FALSE   # TRUE para também baixar os arquivos por ciclo (validação/fallback)

# Extrai o nome de arquivo do cabeçalho Content-Disposition (filename*= ou filename=).
nome_de_content_disposition <- function(cd) {
  if (length(cd) == 0 || is.na(cd) || cd == "") return(NA_character_)
  m <- regmatches(cd, regexpr("filename\\*=[^;]+", cd, ignore.case = TRUE))   # RFC 5987: filename*=UTF-8''...
  if (length(m)) { v <- sub("filename\\*=", "", m, ignore.case = TRUE); v <- sub("^[^']*''", "", v)
                   return(utils::URLdecode(trimws(v))) }
  m <- regmatches(cd, regexpr('filename="?[^";]+"?', cd, ignore.case = TRUE))
  if (length(m)) { v <- sub('filename=', "", m, ignore.case = TRUE); return(gsub('"', "", trimws(v))) }
  NA_character_
}

# ---- 1) Base Única (fonte primária) ------------------------------------------
# Cache: se já houver um *baseunica*.xlsx grande, não rebaixa (apague para forçar nova versão).
existentes <- list.files(dir_sis, pattern = "baseunica.*\\.xlsx$", full.names = TRUE, ignore.case = TRUE)
existentes <- existentes[file.info(existentes)$size > 1e6]
destino_bu <- NULL

if (length(existentes)) {
  destino_bu <- existentes[which.max(file.info(existentes)$mtime)]
  message("(cache) Base Única já presente: ", basename(destino_bu),
          "  (apague para baixar uma versão mais recente)")
} else {
  message("Baixando Base Única do SharePoint da SENAPPEN ...")
  destino_bu <- tryCatch({
    tmp <- tempfile(fileext = ".xlsx")
    resp <- httr2::request(cfg$sisdepen_baseunica_url) |>
      httr2::req_timeout(600) |> httr2::req_perform(path = tmp)         # baixa direto p/ disco
    # nome versionado fornecido pelo SharePoint (embute timestamp da versão); fallback = config
    nome <- nome_de_content_disposition(httr2::resp_header(resp, "content-disposition"))
    if (is.na(nome) || !grepl("\\.xlsx$", nome)) nome <- cfg$sisdepen_baseunica_arq
    dest <- file.path(dir_sis, nome)
    file.rename(tmp, dest)
    if (file.exists(dest) && file.info(dest)$size > 1e6) dest else NULL
  }, error = function(e) { message("⚠ erro: ", conditionMessage(e)); NULL })

  if (is.null(destino_bu)) {
    warning("Download automático falhou ou veio incompleto. ",
            "Baixe manualmente (abrir link no navegador -> Baixar) e salve em:\n  ", dir_sis)
  } else {
    message("Salvo como: ", basename(destino_bu))
  }
}

# Verificação de integridade por md5 (se o arquivo existe e há md5 esperado em config)
if (!is.null(destino_bu) && file.exists(destino_bu) && !is.na(cfg$sisdepen_baseunica_md5)) {
  md5 <- unname(tools::md5sum(destino_bu))
  if (identical(md5, cfg$sisdepen_baseunica_md5)) {
    message("✔ md5 confere (", md5, ")")
  } else {
    warning("md5 DIFERE do esperado.\n  obtido:   ", md5,
            "\n  esperado: ", cfg$sisdepen_baseunica_md5,
            "\n  (pode ser uma nova versão da Base Única — atualizar cfg$sisdepen_baseunica_md5).")
  }
}

if (!is.null(destino_bu) && file.exists(destino_bu)) {
  man <- tibble::tibble(
    arquivo = basename(destino_bu), fonte = "Base Única (SharePoint SENAPPEN)",
    url = cfg$sisdepen_baseunica_url, bytes = file.info(destino_bu)$size,
    md5 = unname(tools::md5sum(destino_bu)), data_download = as.character(Sys.Date()))
  readr::write_csv(man, file.path(dir_sis, "MANIFEST_baseunica.csv"))
  message("Manifesto: data/raw/sisdepen/MANIFEST_baseunica.csv")
}

# ---- 2) Arquivos por ciclo (validação/fallback; opcional) --------------------
if (baixar_ciclos) {
  fontes <- readr::read_csv(here::here("data/raw/sisdepen_fontes.csv"), show_col_types = FALSE) |>
    dplyr::filter(ano %in% cfg$anos_prisional)
  message("SISDEPEN por ciclo: ", nrow(fontes), " ciclos (anos ", paste(range(cfg$anos_prisional), collapse="-"), ")")
  manifesto <- vector("list", nrow(fontes))
  for (i in seq_len(nrow(fontes))) {
    f <- fontes[i, ]
    destino <- file.path(dir_sis, sprintf("ciclo_%02d_%d_sem%d.xlsx", f$ciclo, f$ano, f$semestre))
    if (!(file.exists(destino) && file.info(destino)$size > 0)) {
      message("  baixando ciclo ", f$ciclo, " (", f$ano, "/", f$semestre, ") ...")
      ok <- tryCatch({ utils::download.file(f$url, destino, mode = "wb", quiet = TRUE)
                       file.exists(destino) && file.info(destino)$size > 0 },
                     error = function(e) FALSE)
      if (!ok) { warning("  FALHA ciclo ", f$ciclo, " — baixe manualmente: ", f$url); next }
    }
    manifesto[[i]] <- tibble::tibble(ciclo = f$ciclo, ano = f$ano, semestre = f$semestre,
      url = f$url, arquivo = destino, bytes = file.info(destino)$size,
      md5 = unname(tools::md5sum(destino)), data_download = as.character(Sys.Date()))
  }
  readr::write_csv(dplyr::bind_rows(manifesto), file.path(dir_sis, "MANIFEST_sisdepen.csv"))
  message("Manifesto por ciclo: data/raw/sisdepen/MANIFEST_sisdepen.csv")
}

message("\nOK — aquisição SISDEPEN concluída (fonte primária: Base Única).")
