# =============================================================================
# 00_renv_bootstrap.R — Inicialização do renv (travar versões dos pacotes)
# -----------------------------------------------------------------------------
# Roda UMA vez para criar o renv.lock do projeto (reprodutibilidade). Depois,
# qualquer pessoa reproduz o ambiente com `renv::restore()`.
#
# Uso (no R, na raiz do projeto):  source("scripts/rs/00_renv_bootstrap.R")
# =============================================================================

if (!requireNamespace("renv", quietly = TRUE)) install.packages("renv")

# Pacotes usados pelo pipeline (scripts/rs/*.R e R/*.R):
pacotes <- c(
  "here", "tidyverse",      # tidyverse cobre dplyr, readr, stringr, tidyr, purrr, tibble, ggplot2
  "readxl",                 # leitura de .xlsx (Base Única, oficiais, INEP)
  "stringi",                # normalização de texto / encoding (CP850 etc.)
  "jsonlite",               # API de localidades do IBGE (regiões intermediárias)
  "sidrar",                 # IBGE/SIDRA (população, PIB)
  "httr2",                  # download da Base Única (SharePoint + &download=1, Content-Disposition)
  "zip"                     # descompactação robusta (01a)
  # "microdatasus"          # OPCIONAL (01c, alternativa de mortalidade); via remotes::install_github
)

# Inicializa o renv no projeto (cria renv/, .Rprofile e renv.lock a partir do que está instalado).
# Se preferir um lock só com o que o projeto usa, instale os pacotes acima antes e rode renv::init().
renv::init(bare = FALSE)

# Garante que os pacotes do pipeline estão registrados e snapshota as versões:
install.packages(setdiff(pacotes, rownames(installed.packages())))
renv::snapshot(packages = pacotes, prompt = FALSE)

message("OK — renv.lock criado/atualizado. Reproduzir ambiente depois com: renv::restore()")
message("Para a alternativa de mortalidade via microdatasus (01c), instalar à parte: ",
        "remotes::install_github('rfsaldanha/microdatasus') e renv::snapshot().")
