# =============================================================================
# run_all.R — Orquestrador do Monitor Prisional RS
# -----------------------------------------------------------------------------
# Roda as etapas na ordem correta. Substitui o acoplamento por sessão do Monitor SP:
# cada etapa lê de arquivos e escreve em arquivos; este script só define a ORDEM.
#
# Pré-requisitos (uma vez): renv::restore()  (instala os pacotes do renv.lock)
# Aquisição: rodar 01a/01/01b conforme necessário e preservar snapshots.
# Mandados requerem o snapshot Sinesp indicado em cfg$sinesp_dir.
# Para uma candidata isolada, defina MONITOR_RS_RUN_DIR antes de executar.
#
# Uso:  source("scripts/rs/run_all.R")
# =============================================================================

source(here::here("scripts/rs/00_config.R"))
t0 <- Sys.time(); etapa <- function(f) { message("\n==== ", f, " ===="); source(here::here("scripts/rs", f)) }

# ---- 0. Aquisição (rodar uma vez; idempotente) -------------------------------
# etapa("01a_download_ssp_rs.R")   # ✅ SSP-RS: microdados, indicadores, atividade, semestrais, VCM (zip+unzip)
# etapa("01_download.R")           # ✅ Nacionais: IBGE população/região/PIB (INEP distorção: ver URL_INEP_DISTORCAO)
# etapa("01b_download_sisdepen.R") # ✅ SISDEPEN Base Única (download direto SharePoint+&download=1) com md5; ciclos = fallback
# etapa("01c_download_datasus.R")  # [opcional/alternativo] Saúde MORTALIDADE via microdatasus. Canônico = TABNET (04b)

# ---- 1. Processamento por módulo (lê data/raw -> escreve data/processed) ------
etapa("02_criminal.R")             # SSP-RS criminal 2022–2025; reconciliação municipal e estadual
etapa("02b_atividade.R")           # flagrantes da PC por município e ano
etapa("02c_mandados_sinesp.R")     # mandados cumpridos; série própria, sem somar aos flagrantes
etapa("03_prisional.R")            # Base Única SISDEPEN, cela física 2017–2025; estoque do primeiro semestre
etapa("03b_prisional_derivadas.R") # ✅ derivadas: regime, pena (binning SP), filhos, tipo_penal CORRIGIDO, continentes, óbitos ANUAIS (1º+2º), atendimento/gestantes/lactantes
# 03c_mortalidade.R — DESCONTINUADO (mesclado no 03b; mortalidade agora é anual 1º+2º sem)
etapa("04_contexto.R")             # ✅ região intermediária + população + PIB + distorção idade-série (denominadores)
etapa("04b_saude.R")               # ✅ saúde (TABNET: casos+óbitos TB/hep/HIV); requer os CSV em data/raw/nacional/saude/
etapa("05_planilha_final.R")       # ✅ painéis finais (nomes de SP + id_municipio + ano + taxas/100 mil)
etapa("05b_export_formato_sp.R")   # ✅ export formato DataStudio SP: contexto (wide) + criminal e saúde (longo) — os 3 arquivos em outputs/tabelas/formato_sp/
etapa("06_auditoria.R")            # ✅ auditoria consolidada -> RELATORIO_AUDITORIA.md + qualidade_paineis.csv
etapa("07_validacao_prisional.R")  # ✅ valida correções prisionais (cobertura, óbitos anuais, paridade de nomes, consistência)

message("\nConcluído em ", round(difftime(Sys.time(), t0, units = "secs"), 1), "s. ",
        "Saídas em outputs/tabelas/ e auditoria em outputs/auditoria/.")
