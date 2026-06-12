# Monitor Prisional RS

Pipeline reprodutível que adapta o **Monitor do Sistema Prisional de São Paulo**
(NEV/USP) ao **Rio Grande do Sul**, gerando tabelas (“painéis”) prontas para o
Looker Studio no mesmo padrão de variáveis do monitor paulista — permitindo a
comparação SP ↔ RS.

Autoria: **Guilherme Souza** (2026). Doutorado em Políticas Públicas — UFRGS.

> Inspirado no Monitor do Sistema Prisional de São Paulo (NEV/USP) e em suas
> *Notas Metodológicas*, que orientaram as escolhas de fontes, recortes e indicadores
> reproduzidos aqui para o RS. As divergências em relação ao monitor paulista estão
> documentadas em `docs/` (ver, em especial, `docs/auditoria_tipo_penal_sp.md`).

## O que o projeto produz

Quatro painéis, em `outputs/tabelas/`, com os nomes de variável do Monitor SP,
chave `id_municipio` (IBGE), `nome_regiao_intermediaria` e taxas por 100 mil habitantes:

- **`painel_criminal_municipio_ano.csv`** — município × ano (2022–2025): homicídio
  doloso (vítimas e ocorrências), estupro, roubos e furtos “outros”, prisões em
  flagrante, além de população, PIB e distorção idade-série.
- **`painel_prisional_estabelecimento.csv`** — estabelecimento × ano (SISDEPEN, cela
  física): perfil, capacidade, estrutura, população por regime, faixas de pena, tipo
  penal e mortalidade.
- **`painel_contexto_municipio.csv`** — denominadores e panoramas (população, PIB,
  região intermediária, distorção idade-série).
- **`painel_saude_municipio_ano.csv`** — Panorama de Saúde (DATASUS): casos e óbitos
  por tuberculose, hepatite e HIV (2018–2025, com anos provisórios marcados como `NA`).

## Fontes de dados

- **SSP-RS** — microdados de ocorrências (homicídio, estupro, roubo, furto) e dados
  abertos da Lei 15.610/2021 (prisões em flagrante da Polícia Civil).
- **SISDEPEN / SENAPPEN** — *Base Única* consolidada (todos os ciclos), recorte cela física.
- **IBGE** — população (Censo 2022) e PIB municipal (SIDRA); regiões geográficas
  intermediárias (API de localidades).
- **INEP** — taxa de distorção idade-série (Ensino Fundamental).
- **DATASUS / TABNET** — casos notificados (SINAN) e óbitos (SIM) por TB, hepatite e HIV.

## Como reproduzir

```r
# 1. Ambiente (uma vez): instala os pacotes nas versões travadas
renv::restore()                                   # ou: source("scripts/rs/00_renv_bootstrap.R")

# 2. Aquisição (uma vez, com internet)
source("scripts/rs/01_download.R")                # IBGE (pop/PIB/região), INEP
source("scripts/rs/01a_download_ssp_rs.R")        # SSP-RS (microdados, semestrais, etc.)
source("scripts/rs/01b_download_sisdepen.R")      # SISDEPEN Base Única (SharePoint)
#   Saúde: exportar as tabelas do TABNET para data/raw/nacional/saude/ (ver docs)

# 3. Processamento (lê data/raw -> escreve data/processed e outputs/)
source("scripts/rs/run_all.R")
```

A Base Única do SISDEPEN é baixada **automaticamente** pelo `01b_download_sisdepen.R`
(link de compartilhamento do SharePoint + `&download=1`, nome versionado e checagem de
md5). O único passo **manual** é a exportação das tabelas de saúde do TABNET para
`data/raw/nacional/saude/` (documentado em `docs/decisoes_metodologicas.md`); todo o
restante é scriptado. Integridade conferida por manifestos com md5.

## Estrutura

```
scripts/rs/      pipeline numerado (00 config → 06 auditoria) + run_all.R
R/               funções reutilizáveis
data/raw/        dados brutos (NÃO versionados; só manifestos/fontes/esquema)
data/processed/  bases derivadas
outputs/         tabelas (painéis) e auditoria (relatório consolidado)
docs/            documentação metodológica, auditorias e pautas
```

## Princípios de reprodutibilidade

Pipeline modular sem acoplamento por sessão (cada etapa lê/escreve arquivos);
parâmetros e caminhos centralizados em `scripts/rs/00_config.R`; versões de pacotes
travadas via `renv`; auditoria por etapa consolidada em
`outputs/auditoria/RELATORIO_AUDITORIA.md`. Dados brutos grandes ficam fora do Git.

## Notas metodológicas e ressalvas

Decisões e limitações estão registradas em `docs/`:
`decisoes_metodologicas.md`, `problemas_dados.md`, `auditoria_tipo_penal_sp.md`,
`consultas_ssp_rs.md` e `pontos_reuniao_equipe_sp.md`. Destaques: furtos de 2022 com
sub-registro no microdado aberto da SSP-RS; cobertura temporal heterogênea da saúde
(hepatite consolidada só até 2023); denominador populacional fixo no Censo 2022.

## Como citar

> SOUZA, Guilherme. *Monitor Prisional RS*: pipeline reprodutível de indicadores do
> sistema prisional do Rio Grande do Sul, adaptado do Monitor do Sistema Prisional de
> São Paulo (NEV/USP). 2026.

## Licença e uso de dados

Os dados brutos pertencem às respectivas fontes oficiais (SSP-RS, SENAPPEN, IBGE,
INEP, DATASUS) e não são redistribuídos neste repositório — são obtidos pelos scripts
de aquisição. O código é de autoria de Guilherme Souza.
