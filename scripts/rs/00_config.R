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
  anos          = 2022:2025,          # janela da PoC (era dos microdados Mensais)
  saude_anos    = 2018:2025,          # janela do Panorama de Saúde (como SP, desde 2018)
  # Último ano CONSOLIDADO por indicador de saúde (valores além viram NA = provisório/não publicado).
  # Ajustar conforme as notas de atualização de cada fonte (TABNET/SIM).
  saude_ano_max_default = 2024L,      # SINAN casos e SIM óbitos: 2025 ainda provisório (jun/2026)
  saude_ano_max         = list(casos_hepatite = 2023L),  # hepatites virais consolidadas só até 2023
  n_municipios  = 497,                # municípios do RS (para auditoria de cobertura)

  # --- Escolhas metodológicas (decididas para a PoC; ver docs/decisoes_metodologicas.md) ---
  # Cada escolha é um parâmetro: mudar a decisão = mudar aqui, sem reescrever o pipeline.
  escolhas = list(
    estupro_fonte   = "microdado",      # "microdado" (total, comparável a SP) | "vcm" | "ambos"
    roubo_furto     = "estrito_micro",  # "estrito_micro" (reconstrução padrão SP) | "agregado"
    homicidio       = "ambos",          # "ambos" = hd_vitima (oficial) + hd_ocorrencias (micro)
    calcular_taxas  = TRUE,             # taxas por 100 mil habitantes
    consumado_apenas = TRUE,            # tabelas oficiais são "fato consumado"

    # --- Prisional (SISDEPEN) ---
    sisdepen_fonte   = "base_unica",    # "base_unica" (consolidada SENAPPEN; recomendado) | "ciclos"
    prisional_recorte = "cela_fisica",  # "cela_fisica" (exclui domiciliar/monit. eletrônica) | "todos"
    prisional_semestre = 1L             # semestre da base BRUTA (03): 1 = perfil/capacidade (como SP).
                                        # Mortalidade (03b) é ANUAL (1º+2º sem) e ignora este parâmetro.
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
  # O valor abaixo é só FALLBACK, caso o cabeçalho não venha.
  sisdepen_baseunica_arq = "sisdepen_baseunica_2025-2_25032026-163420.xlsx",
  sisdepen_baseunica_md5 = "a4ab2749887c49879b47b10fc72d86b4"  # md5 da versão validada (25/03/2026). Aviso (não erro) se mudar.
)

# ---- Caminhos ----------------------------------------------------------------
# Raiz dos dados da SSP-RS: prefere os baixados por 01a_download_ssp_rs.R
# (data/raw/ssp_rs); se ainda não foram baixados, usa a pasta manual existente.
# Os scripts localizam os arquivos por padrão de nome, recursivamente, sob esta raiz
# (independe da estrutura de subpastas — robusto a zip extraído em qualquer lugar).
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

# ---- Mapa ano -> arquivo de microdado ---------------------------------------
# Os nomes dos arquivos da SSP-RS são irregulares; resolvemos por padrão "JAN_DEZ_AAAA"
# (ignorando arquivos mensais avulsos). Centralizar aqui evita erro em cada script.
arquivo_microdado <- function(ano) {
  arqs <- list.files(paths$raw_crim, pattern = "\\.csv$", full.names = TRUE, recursive = TRUE)
  alvo <- arqs[str_detect(basename(arqs), regex(paste0("JAN_DEZ_", ano), ignore_case = TRUE))]
  if (length(alvo) == 0) stop("Microdado JAN_DEZ não encontrado para o ano ", ano)
  alvo[which.max(file.info(alvo)$size)]   # se houver mais de um, o maior (versão completa)
}

# ---- SISDEPEN: localizar a Base Única consolidada ----------------------------
# A Base Única (todos os ciclos em arquivo único, com campo "Tipo de Recolhimento"
# preenchido em 100% dos anos e ID de estabelecimento estável entre ciclos) é a
# fonte recomendada. É baixada MANUALMENTE do SharePoint da SENAPPEN (link de
# visualizador, não scriptável) e colocada em data/raw/sisdepen/. Documentado em
# docs/decisoes_metodologicas.md. Os arquivos por ciclo (01b) ficam como
# validação/fallback (cfg$escolhas$sisdepen_fonte = "ciclos").
arquivo_baseunica <- function() {
  cands <- list.files(here("data/raw/sisdepen"), pattern = "baseunica.*\\.xlsx$",
                      full.names = TRUE, recursive = TRUE, ignore.case = TRUE)
  if (length(cands) == 0)
    stop("Base Única do SISDEPEN não encontrada em data/raw/sisdepen/. ",
         "Baixe-a do SharePoint da SENAPPEN e coloque-a lá (padrão de nome: *baseunica*.xlsx).")
  cands[which.max(file.info(cands)$mtime)]   # a mais recente
}

message("Config carregada — UF=", c