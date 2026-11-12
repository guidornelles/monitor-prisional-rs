# =============================================================================
# 00_config.R — Configuração central da PoC do Monitor Prisional RS
# -----------------------------------------------------------------------------
# Centraliza TODOS os parâmetros e caminhos. Nenhum outro script deve conter
# caminhos absolutos ou escolhas metodológicas "hardcoded" — tudo vem daqui.
# Isso resolve um dos problemas de reprodutibilidade do Monitor SP (parâmetros
# e filtros espalhados pelo código).
#
# Uso: todo script do pipeline começa com `source(here::here("scripts/rs/00_config.R"))`.
# =============================================================================

# ---- Pacotes -----------------------------------------------------------------
# (instalados/travados via renv; ver renv.lock)
suppressPackageStartupMessages({
  library(here)        # caminhos relativos à raiz do projeto (reprodutibilidade)
  library(tidyverse)   # dplyr, readr, stringr, tidyr, purrr
  library(readxl)      # leitura de .xlsx (tabelas oficiais)
})

# ---- Parâmetros do projeto ---------------------------------------------------
cfg <- list(
  uf            = "RS",
  anos_criminal = 2022:2025,          # anos completos da camada municipal
  anos_prisional = 2017:2025,        # janela candidata da Base Única SISDEPEN
  sinesp_dir    = here("data/raw/sinesp_vde/2026-10-03"), # extração com reconciliação auditada
  saude_anos    = 2018:2025,          # janela do Panorama de Saúde (como SP, desde 2018)
  # Último ano CONSOLIDADO por indicador de saúde (valores além viram NA = provisório/não publicado).
  # Ajustar conforme as notas de atualização de cada fonte (TABNET/SIM).
  saude_ano_max_default = 2024L,      # SINAN casos e SIM óbitos: 2025 ainda provisório (jun/2026)
  saude_ano_max         = list(casos_hepatite = 2023L),  # hepatites virais consolidadas só até 2023
  n_municipios  = 497,                # municípios do RS (para auditoria de cobertura)

  # --- Parâmetros efetivamente consumidos pelas rotinas -----------------------
  # Estupro total, patrimônio estrito e vítimas de homicídio são definidos no 02;
  # não há chave que troque automaticamente a unidade ou a fonte dessas séries.
  escolhas = list(
    consumado_apenas = TRUE,            # tabelas oficiais são "fato consumado"

    # --- Prisional (SISDEPEN) ---
    sisdepen_fonte   = "base_unica",    # ciclos avulsos são insumo de conferência, não opção de 03
    prisional_recorte = "cela_fisica",  # "cela_fisica" (exclui domiciliar/monit. eletrônica) | "todos"
    prisional_semestre = 1L             # semestre da base BRUTA (03): 1 = perfil/capacidade (como SP).
                                        # 03b requer esse estoque e apura a cobertura dos dois semestres.
  ),

  # --- Tolerâncias de auditoria (reconciliação microdado x agregado oficial) ---
  tol_estadual_pct = 2.0,   # desvio estadual aceitável (%)
  tol_municipio    = 0.01,  # desvio municipal aceitável (fração) p/ contar como "ok"

  # --- SISDEPEN Base Única: download direto do SharePoint da SENAPPEN ----------
  # O link de compartilhamento + "&download=1" devolve o arquivo direto (testado/funcional).
  # Ao sair uma nova versão consolidada, atualizar URL e nome do arquivo abaixo.
  sisdepen_baseunica_url = "https://justicagovbr-my.sharepoint.com/:x:/g/personal/imprensa_senappen_mj_gov_br/IQCm_un5JRm_Sap9twKqwbLpAYSkLilJ6C5x7BwSn7rGKCg?e=93UpsP&download=1",
  # Nome do arquivo: o 01b usa o nome fornecido pelo SharePoint (Content-Disposition),
  # que embute o timestamp da versão (ex.: sisdepen_baseunica_2025-2_25032026-163420.xlsx).
  # A execução usa esta versão validada; atualize nome e hash ao adotar nova extração.
  sisdepen_baseunica_arq = "sisdepen_baseunica_2025-2_25032026-163420.xlsx",
  sisdepen_baseunica_md5 = "a4ab2749887c49879b47b10fc72d86b4"
)

# ---- Caminhos ----------------------------------------------------------------
# Raiz dos dados da SSP-RS: prefere os baixados por 01a_download_ssp_rs.R
# (data/raw/ssp_rs); se ainda não foram baixados, usa a pasta manual existente.
# A versão candidata seleciona as entradas criminais pelo catálogo fixado.
.ssp_root <- if (dir.exists(here("data/raw/ssp_rs")) &&
                 length(list.files(here("data/raw/ssp_rs"), recursive = TRUE,
                                   pattern = "\\.(csv|xlsx|xls)$")) > 0) {
  here("data/raw/ssp_rs")
} else {
  here("data/EstatisticasCriminaisRS")
}
message("Raiz de dados SSP-RS: ", .ssp_root)

paths <- list(
  ssp_root   = .ssp_root,
  raw_crim   = .ssp_root,   # microdados (busca recursiva por JAN_DEZ_AAAA)
  ind_crim   = .ssp_root,   # tabelas oficiais (busca recursiva; seleção pela aba do ano)
  vcm_dir    = .ssp_root,
  raw        = here("data/raw"),            # downloads nacionais (SISDEPEN, IBGE, INEP, DATASUS)
  intermediate = here("data/intermediate"),
  processed  = here("data/processed"),
  out_tab    = here("outputs/tabelas"),
  out_aud    = here("outputs/auditoria")
)

# Permite regenerar uma candidata sem substituir as saídas em uso.
.run_dir <- Sys.getenv("MONITOR_RS_RUN_DIR")
if (nzchar(.run_dir)) {
  paths$intermediate <- file.path(.run_dir, "intermediate")
  paths$processed <- file.path(.run_dir, "processed")
  paths$out_tab <- file.path(.run_dir, "tabelas")
  paths$out_aud <- file.path(.run_dir, "auditoria")
}
invisible(lapply(paths[c("intermediate", "processed", "out_tab", "out_aud")],
                 dir.create, recursive = TRUE, showWarnings = FALSE))

catalogo_ssp <- function() readr::read_csv(here("data/raw/ssp_rs_fontes.csv"),
                                           show_col_types = FALSE)
fonte_ssp <- function(categoria, ano) {
  f <- catalogo_ssp() |> dplyr::filter(.data$categoria == .env$categoria,
                                      .data$chave == as.character(ano))
  if (nrow(f) != 1L) stop("Esperava uma versão de ", categoria, " / ", ano)
  nome <- basename(sub("\\?.*$", "", f$url))
  file.path(paths$ssp_root, categoria, ano, nome)
}

# O CSV fica em uma pasta identificada pelo ZIP publicado, sem sobrepor extrações anteriores.
arquivo_microdado <- function(ano) {
  pasta <- tools::file_path_sans_ext(fonte_ssp("mensais", ano))
  alvo <- list.files(pasta, pattern = "\\.csv$", full.names = TRUE,
                     recursive = TRUE, ignore.case = TRUE)
  if (length(alvo) != 1L) stop("Esperava um CSV anual em ", pasta, "; rode 01a_download_ssp_rs.R")
  alvo[[1]]
}

# ---- SISDEPEN: localizar a Base Única consolidada ----------------------------
# O 01b pode baixar a Base Única; 03 e 03b leem o arquivo fixado para reprodução.
arquivo_baseunica <- function() {
  arq <- file.path(paths$raw, "sisdepen", cfg$sisdepen_baseunica_arq)
  if (!file.exists(arq)) stop("Base Única SISDEPEN fixada não encontrada: ", arq)
  if (!identical(unname(tools::md5sum(arq)), cfg$sisdepen_baseunica_md5))
    stop("Hash divergente para a Base Única fixada: ", arq)
  arq
}

message("Config carregada — UF=", cfg$uf,
        " | criminal=", paste(range(cfg$anos_criminal), collapse = "-"),
        " | prisional=", paste(range(cfg$anos_prisional), collapse = "-"),
        " | SISDEPEN=", cfg$escolhas$sisdepen_fonte)
