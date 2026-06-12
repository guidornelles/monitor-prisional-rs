# =============================================================================
# commitar_poc.ps1 -- Sequencia de commits da PoC do Monitor Prisional RS
# -----------------------------------------------------------------------------
# Rodar na RAIZ do repositorio, no PowerShell, APOS conferir 'git status'.
# Faz commits pequenos e coerentes e tem uma TRAVA DE SEGURANCA que aborta se
# algum arquivo grande (>5 MB) ou dado bruto for parar no stage.
#
# Pre-requisito p/ o commit do renv: rodar antes, no R:
#   source("scripts/rs/00_renv_bootstrap.R")
# Execucao (uma das opcoes):
#   powershell -ExecutionPolicy Bypass -File .\scripts\commitar_poc.ps1
# =============================================================================

$ErrorActionPreference = "Stop"
$LIMITE_MB = 5

function Confere-Stage {
  $staged = git diff --cached --name-only
  foreach ($f in $staged) {
    if (-not (Test-Path $f)) { continue }
    $mb = [math]::Round((Get-Item $f).Length / 1MB, 2)
    if ($mb -gt $LIMITE_MB) { throw "ABORTADO: arquivo grande no stage: $f ($mb MB). Confira o .gitignore." }
    if (($f -like "data/EstatisticasCriminaisRS/*") -or ($f -like "*baseunica*.xlsx") -or
        (($f -like "*.xlsx") -and ($f -like "data/raw/*"))) {
      throw "ABORTADO: dado bruto no stage: $f. Confira o .gitignore."
    }
  }
}

function Commit-Grupo([string]$msg, [string[]]$paths) {
  git reset | Out-Null
  $existentes = $paths | Where-Object { Test-Path $_ }
  if (-not $existentes) { Write-Host "  (pulado, sem arquivos) $msg"; return }
  git add -- $existentes
  Confere-Stage
  $n = (git diff --cached --name-only | Measure-Object).Count
  if ($n -eq 0) { Write-Host "  (nada a commitar) $msg"; return }
  git commit -m $msg | Out-Null
  Write-Host "  [OK $n arq] $msg"
}

Write-Host "== git status atual =="
git status --short

Write-Host ""
Write-Host "== Criando commits =="

Commit-Grupo "Configuracao do repositorio e politica de versionamento" `
  @(".gitignore", "monitor-prisional-rs.Rproj", "AGENTS.md", "CLAUDE.md", "README.md")

Commit-Grupo "Aquisicao reproduzivel (SSP-RS, IBGE, SISDEPEN Base Unica, DATASUS) e manifestos" `
  @("scripts/rs/00_config.R", "scripts/rs/00_renv_bootstrap.R",
    "scripts/rs/01_download.R", "scripts/rs/01a_download_ssp_rs.R",
    "scripts/rs/01b_download_sisdepen.R", "scripts/rs/01c_download_datasus.R",
    "data/raw/ssp_rs_fontes.csv", "data/raw/sisdepen_fontes.csv",
    "data/raw/sp_schema_prisional.csv", "data/raw/sisdepen/MANIFEST_baseunica.csv")

Commit-Grupo "Pipeline de processamento: criminal, atividade, prisional, contexto, saude, paineis e auditoria" `
  @("R", "scripts/rs/02_criminal.R", "scripts/rs/02b_atividade.R",
    "scripts/rs/03_prisional.R", "scripts/rs/03b_prisional_derivadas.R", "scripts/rs/03c_mortalidade.R",
    "scripts/rs/04_contexto.R", "scripts/rs/04b_saude.R",
    "scripts/rs/05_planilha_final.R", "scripts/rs/06_auditoria.R",
    "scripts/rs/run_all.R", "scripts/rs/README.md", "scripts/commitar_poc.ps1")

Commit-Grupo "Documentacao metodologica, auditorias e pautas (reuniao SP / consulta SSP-RS)" `
  @("docs")

Commit-Grupo "Paineis finais, bases derivadas e relatorios da PoC" `
  @("outputs", "data/processed")

Commit-Grupo "Trava de versoes dos pacotes (renv)" `
  @("renv.lock", ".Rprofile", "renv/settings.json", "renv/activate.R", "renv/.gitignore")

Write-Host ""
Write-Host "== Estado final =="
git status --short
Write-Host ""
Write-Host "Proximo passo: criar o repo remoto (monitor-prisional-rs) e 'git push -u origin main'."
Write-Host "Confira 'git log --oneline' antes de publicar."
