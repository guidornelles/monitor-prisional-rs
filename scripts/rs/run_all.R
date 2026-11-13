# =============================================================================
# run_all.R — Orquestrador do Monitor Prisional RS
# -----------------------------------------------------------------------------
# Executa as etapas na ordem de suas dependências. Cada etapa lê e grava arquivos.
#
# Pré-requisitos (uma vez): renv::restore()  (instala os pacotes do renv.lock)
# Aquisição: rodar 01a/01/01b conforme necessário e preservar snapshots.
# Mandados requerem o snapshot Sinesp indicado em cfg$sinesp_dir.
# Para uma candidata isolada, defina MONITOR_RS_RUN_DIR antes de executar.
#
# Uso: Rscript scripts/rs/run_all.R, a partir da raiz do projeto.
# =============================================================================

source(here::here("scripts/rs/00_config.R"))
t0 <- Sys.time(); etapa <- function(f) { message("\n==== ", f, " ===="); source(here::here("scripts/rs", f)) }

# A aquisição é uma etapa separada, descrita em scripts/rs/README.md.

# ---- 1. Processamento por módulo (lê data/raw -> escreve data/processed) ------
etapa("02_criminal.R")             # SSP-RS criminal 2022–2025; reconciliação municipal e estadual
etapa("02b_atividade.R")           # registros de flagrante por município e ano
etapa("02c_mandados_sinesp.R")     # mandados cumpridos; série própria, sem somar aos flagrantes
etapa("03_prisional.R")            # Base Única SISDEPEN, cela física 2017–2025; estoque do primeiro semestre
etapa("03b_prisional_derivadas.R") # indicadores derivados e cobertura de óbitos dos dois semestres
etapa("04_contexto.R")             # cadastro municipal, região e denominador das taxas
etapa("04b_saude.R")               # TabNet: casos e óbitos por indicador e competência
etapa("05_planilha_final.R")       # tabelas analíticas com chaves e taxas
etapa("05b_export_formato_sp.R")   # tabelas de conexão no subdiretório formato_sp
etapa("06_auditoria.R")            # auditoria de cobertura, chaves e reconciliação
etapa("07_validacao_prisional.R")  # testes de consistência da camada prisional

message("\nConcluído em ", round(difftime(Sys.time(), t0, units = "secs"), 1), " s.",
        "\nTabelas: ", paths$out_tab, "\nAuditoria: ", paths$out_aud)
