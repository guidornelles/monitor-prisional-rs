# =============================================================================
# run_all.R — Orquestrador do pipeline da PoC do Monitor Prisional RS
# -----------------------------------------------------------------------------
# Roda as etapas na ordem correta. Substitui o acoplamento por sessão do Monitor SP:
# cada etapa lê de arquivos e escreve em arquivos; este script só define a ORDEM.
#
# Pré-requisitos (uma vez): renv::restore()  (instala os pacotes do renv.lock)
# Aquisição (uma vez, com internet): rodar 01a e 01 antes do processamento.
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
etapa("02_criminal.R")             # ✅ pronto e validado (2022–2025); auditoria automática
etapa("02b_atividade.R")           # ✅ prisões em flagrante (PC) por município×ano (Lei 15.610 Art.6 IX)
etapa("03_prisional.R")            # ✅ Base Única SISDEPEN -> base prisional (padrão Base_Sisdepen); cela física
etapa("03b_prisional_derivadas.R") # ✅ derivadas (regime, pena, pena_remanescente, filhos, tipo_penal CORRIGIDO)
etapa("03c_mortalidade.R")         # ✅ mortalidade prisional (seção 6.8, 2º semestre)
etapa("04_contexto.R")             # ✅ região intermediária + população + PIB + distorção idade-série (denominadores)
etapa("04b_saude.R")               # ✅ saúde (TABNET: casos+óbitos TB/hep/HIV); requer os CSV em data/raw/nacional/saude/
etapa("05_planilha_final.R")       # ✅ painéis finais (nomes de SP + id_municipio + ano + taxas/100 mil)
etapa("06_auditoria.R")            # ✅ auditoria consolidada -> RELATORIO_AUDITORIA.md + qualidade_paineis.csv

message("\nConcluído em ", round(difftime(Sys.time(), t0, units = "secs"), 1), "s. ",
        "Saídas em outputs/tabelas/ e auditoria em outputs/auditoria/.")
