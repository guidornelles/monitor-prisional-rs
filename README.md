# Monitor Prisional RS

Pipeline reprodutível que adapta o **Monitor do Sistema Prisional de São Paulo**
(NEV/USP) ao **Rio Grande do Sul**, gerando tabelas (“painéis”) prontas para o
Looker Studio no mesmo padrão de variáveis do monitor paulista — permitindo a
comparação SP ↔ RS.

Autoria: **Guilherme Souza** (2026). Doutorando em Políticas Públicas — UFRGS.

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
  física). Espelha a base `base_sisdepen` de SP no lado bruto (≈444 colunas das seções
  1–7 do SISDEPEN) e acrescenta as derivadas no padrão de SP: perfil, capacidade,
  população por regime, faixas de pena e pena remanescente, tipo penal, filhos,
  nacionalidade por continente, educação (6.3), trabalho, saúde (consultas 6.6 e agravos
  transmissíveis 6.7), pessoal (médicos), alas exclusivas (LGBT/idosos/indígenas/
  estrangeiros), endereço pronto para o mapa, ano de inauguração e **mortalidade ANUAL
  (1º + 2º semestre)**.
- **`painel_contexto_municipio.csv`** — denominadores e panoramas (população, PIB,
  região intermediária, distorção idade-série, presença de estabelecimento penal `munic_ep`).
- **`painel_saude_municipio_ano.csv`** — Panorama de Saúde (DATASUS): casos e óbitos
  por tuberculose, hepatite e HIV (2018–2025, com anos provisórios marcados como `NA`).

**Export no formato do DataStudio de SP.** Além dos painéis internos (snake_case, fonte da
verdade), o passo `05b_export_formato_sp.R` emite em `outputs/tabelas/formato_sp/` as bases já no
**formato e nomes que o Looker de SP usa** — `contexto_dados.csv` (wide), `dinamica_criminal.csv` e
`dados_saude.csv` (longo, com coluna `Crime`/`Tipo` + `taxa` + `tem_EP`/`Tem_prisão`). Isso permite
**importação plug-and-play** no DataStudio, sem renomear campo a campo. A camada prisional não tem
export à parte: o próprio `painel_prisional_estabelecimento.csv` já espelha o `base_sisdepen` de SP.

As apreensões de **armas** ficam em tabela estadual à parte (`armas_rs_estadual_ano.csv`), pois no
RS só existem em nível estadual.

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
scripts/rs/      pipeline numerado (00 config → 07 validação prisional) + run_all.R
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
sub-registro no microdado aberto da SSP-RS; **tempo de pena do RS não-confiável** — o
SISDEPEN do RS concentra ~78% dos condenados na faixa "Até 6 meses" (5.12 e 5.13), vs.
~5% em SP, indicando preenchimento incorreto na origem; cobertura temporal heterogênea
da saúde (hepatite consolidada só até 2023); denominador populacional fixo no Censo 2022.

## Como citar

> SOUZA, Guilherme. *Monitor Prisional RS*: pipeline reprodutível de indicadores do
> sistema prisional do Rio Grande do Sul, adaptado do Monitor do Sistema Prisional de
> São Paulo (NEV/USP). 2026.

## Licença e uso de dados

Os dados brutos pertencem às respectivas fontes oficiais (SSP-RS, SENAPPEN, IBGE,
INEP, DATASUS) e não são redistribuídos neste repositório — são obtidos pelos scripts
de aquisição. O código é de autoria de Guilherme Souza.
