# Inventário do repositório Monitor do Sistema Prisional (SP)

> **Inspeção complementar de 03/10/2026:** o export local da dinâmica criminal contém 2001, 2023 e 2025; a tabela `dados_ssp_2023.xlsx` confirma os totais de 2023. A branch `R`, em `validation/criminal_data_proccessing.R`, lê janeiro–junho e julho–novembro de 2025 e conta registros. A auditoria [Sinesp VDE](auditoria_sinesp_vde_2026-10-03.md) separa esse período parcial de anos integrais e identifica diferenças de composição/unidade. A inspeção não alterou o repositório SP e não prova a regeneração do painel online. O inventário histórico abaixo permanece datado.

> Documento de inspeção. Descreve **fatos observados** no repositório local `MonitorPrisional2024` (fonte de inspeção, **não modificado**). Inferências sobre viabilidade de adaptação para o RS são tratadas em outros documentos (`docs/diagnostico_viabilidade_rs.md`).
>
> Data da inspeção: 2026-06-09.

## 1. Identificação do repositório

| Item | Valor observado |
|------|-----------------|
| Remoto | `https://github.com/nevusp/MonitorPrisional2024.git` |
| Nome original | `NEV_2024` (NEV/USP) |
| Autoria dos scripts | Leonardo Carvalho (usuário GitHub `leonardocps`) |
| Projeto RStudio | `Consultoria NEV sobre sistema prisional.Rproj` |
| Produto final | Painel **Monitor do Sistema Prisional** no Looker Studio |
| Painel (Looker Studio) | `https://lookerstudio.google.com/u/1/reporting/f3416e66-3d3e-40ed-822c-5920a6ede637` |
| Planilha de abastecimento | Google Sheets `1JLjy8je7okAKx7XeB-8m6ZdxcNzLg_uNcAGb7RBoqxc` |

### Particularidade estrutural: conteúdo distribuído em branches

O repositório **não organiza código e dados em diretórios na branch principal**. A branch `main` contém apenas `README.md` e o `.Rproj` — o último commit (`1e17cd9 "Delete R directory"`) removeu os scripts de `main`. O conteúdo real está espalhado por branches distintas:

| Branch | Conteúdo |
|--------|----------|
| `main` | Apenas README + .Rproj (scripts removidos) |
| `R` | **Todos os scripts R** (tip: commit `efe1a1a`) — fonte canônica do código |
| `data-raw` | Bases intermediárias, dicionários e outputs gerados (`.xlsx`) + `depen.R` |
| `depen` | Igual a `data-raw` + `depen.R` |
| `sem_01` | Bases + `depen.R` + arquivo solto `dsds.txt` |
| `sem_02` | Bases + **arquivos brutos dos ciclos SISDEPEN de 2º semestre** (2017–2023) |

> Observação metodológica: para reconstruir o pipeline é preciso combinar a branch `R` (scripts) com `data-raw`/`sem_01`/`sem_02` (dados). Essa fragmentação é um risco de reprodutibilidade a registrar para o RS.

## 2. Scripts (branch `R`, commit `efe1a1a`)

Linguagem única: **R**. Não há `Makefile`, `targets`, nem orquestrador — a ordem de execução é manual/implícita.

### 2.1 Pipeline principal

**`depen.R`** (≈1.207 linhas) — Consolidação do 1º semestre.
- `library(tidyverse)`.
- Função `carrega_base_depen(caminho, ano)`: lê cada ciclo via `readxl::read_excel`, gera `id = Nome do Estabelecimento-UF-ano`, zera NAs numéricos e **filtra `UF == "SP"`**.
- Lê 8 ciclos de **1º semestre** (2017–2024), de `data-raw/depen/sem_01/` (2º, 4º, 6º, 8º, 10º, 12º, 14º, 16º ciclos).
- Funções auxiliares de robustez: `garante_coluna`, `renomeia_coluna_segura`.
- Funções de extração por seção do questionário SISDEPEN: `identifica`, `perfil`, `variaveis_1_2`, `variaveis_3_4`, `variaveis_5`, `variaveis_6`, `variaveis_7`, `nacionalidade` (cada uma faz `select` + `rbind` acumulando todos os anos).
- Montagem final: `base_perfil <- cbind(base_identifica, base_perfil)`; `base_sisdepen <- cbind(base_identifica, base_variaveis_1_2, ...)`.
- **Saídas:** `data-raw/Perfil_SP.xlsx` e `data-raw/Base_Sisdepen.xlsx` (via `writexl::write_xlsx`).

**`dados_sem2.R`** (≈154 linhas) — Incorpora o 2º semestre (mortalidade/saúde).
- `library(tidyverse)`.
- `carrega_base_depen_sem2(caminho, ano)`: mesma lógica de carga, filtro `UF == "SP"`.
- Lê 8 ciclos de **2º semestre** (2017–2024) de `data-raw/depen/sem_02/` (3º, 5º, 7º, 9º, 11º, 13º, 15º, 17º ciclos).
- Função `obitossem2`: renomeia/seleciona variáveis da seção **6.8 Mortalidade no Sistema Prisional** (óbitos por saúde, criminais, suicídios, acidentais, causa desconhecida — M/F/Total), consultas médicas/odontológicas (6.6), cela para gestantes (2.1) e lactantes (5.9).
- **Dependência em memória:** faz `left_join(base_sisdepen, base_obitossem2, by = "id")` — exige que `depen.R` tenha sido executado antes **na mesma sessão R** (a base intermediária não é persistida entre scripts).
- **Saída:** sobrescreve `data-raw/Base_Sisdepen.xlsx` com a base anual consolidada (esta é a planilha que alimenta o monitor).

**`dados municípios_variaveis.R`** (≈94 linhas) — Variáveis socioeconômicas/criminais de contexto municipal.
- `library(basedosdados)`, `library(tidyverse)`.
- **Conecta ao Google BigQuery via `basedosdados`** com `set_billing_id("prisional-system-monitor")` (billing GCP específico).
- Tabelas consultadas (`bdplyr`/`bd_collect`): `br_ibge_populacao.municipio`, `br_bd_diretorios_brasil.municipio`, `br_sp_gov_ssp.ocorrencias_registradas`, `br_ibge_pib.municipio`, `br_inep_ideb.municipio`.
- Filtra municípios de SP (`sigla_uf == "SP"` / `id_municipio` iniciando em `35`).
- Lê ainda CSV externo de outro projeto: `../isdp_scraper/output/base_mensal/base_mensal_v8_2023.csv` (via `read.csv2`).
- **Saídas:** `data-raw/populacao_municipios_sp.xlsx`, `pib_municipios_sp.xlsx`, `ideb_municipios_sp.xlsx`, `dados_ssp_2023.xlsx`.

### 2.2 Scripts de validação (`validation/`)

**`validation/analysis.R`** (≈29 linhas) — QA de colunas. Compara o conjunto de colunas da base do monitor (`validation/data/base_sisdepen_monitor.xlsx`) com a base gerada (`data-raw/Base_Sisdepen.xlsx`) via `setdiff`. Pacotes: `readxl`, `dplyr`, `stringr`.

**`validation/criminal_data_proccessing.R`** (≈149 linhas) — Processa dados criminais da SSP-SP (2025). Lê `validation/data/criminais/SPDadosCriminais_2025.xlsx` (abas JAN–JUN e JUL–NOV) e `DadosProdutividade_2025.xlsx` (prisões, armas apreendidas); usa de-para de municípios (`de-para_municipios_ssp.xlsx`); padroniza crimes de interesse (homicídio doloso, estupros, roubo/furto outros, prisões, armas). **Saída:** `validation/data/criminais/resultado_final_criminais_sp.xlsx`. Pacotes: `tidyverse`, `readxl`, `writexl`.

**`validation/health_data_processing.R`** (≈86 linhas) — Processa dados de saúde municipal (CSVs de HIV, tuberculose, hepatite — casos e óbitos) em `validation/data/saude/`, cruzando com `validation/data/sp_municipios.xlsx`. **Saída:** `validation/data/saude/resultado_final_saude_sp.xlsx`. Pacotes: `readxl`, `writexl`, `tidyverse`, `stringr`.

`validation/README.md` existe mas está vazio.

## 3. Etapas do pipeline

```
Bases brutas SISDEPEN (gov.br) ─┐
  sem_01: ciclos 2,4,6,8,10,12,14,16 (2017–2024)
  sem_02: ciclos 3,5,7,9,11,13,15,17 (2017–2024)
                                 │
                 [1] depen.R  (filtra UF==SP; consolida 1º sem; seções 1–7 + perfil + nacionalidade)
                                 │── Perfil_SP.xlsx
                                 └── base_sisdepen (em memória) + Base_Sisdepen.xlsx
                                 │
                 [2] dados_sem2.R  (consolida 2º sem; mortalidade 6.8; left_join base_sisdepen)
                                 └── Base_Sisdepen.xlsx (final, anual)  ──► Google Sheets ──► Looker Studio

Contexto municipal (paralelo):
  BigQuery/basedosdados (IBGE pop/PIB, INEP IDEB, SSP-SP) + isdp_scraper CSV
                 [3] dados municípios_variaveis.R
                 └── populacao/pib/ideb/dados_ssp _municipios_sp.xlsx

Validação/QA (paralelo):
  [4] analysis.R · criminal_data_proccessing.R · health_data_processing.R
      └── resultado_final_*.xlsx
```

Ordem obrigatória: **`depen.R` → `dados_sem2.R`** (acoplamento por objeto em memória `base_sisdepen`, não por arquivo). Os scripts de município e validação são independentes.

## 4. Fontes de dados

| Fonte | Origem | Específico de SP? | Uso |
|-------|--------|-------------------|-----|
| **SISDEPEN / SENAPPEN** (bases por ciclo/semestre) | gov.br/senappen — `bases-de-dados` | Nacional; filtrado para `UF=="SP"` no código | Insumo principal do monitor |
| Dicionário de Variáveis / `mapa_variaveis_SISDEPEN` / `Variaveis_Secoes1_2` / `Variaveis_Secoes1a4` | Arquivos `.xlsx` em `data-raw` | Não (estrutura SISDEPEN nacional) | Referência de variáveis |
| IBGE população (`br_ibge_populacao.municipio`) | BigQuery / basedosdados | Não (filtrado p/ SP) | Contexto municipal |
| IBGE PIB (`br_ibge_pib.municipio`) | BigQuery / basedosdados | Não (filtrado p/ SP) | Contexto municipal |
| INEP IDEB (`br_inep_ideb.municipio`) | BigQuery / basedosdados | Não (filtrado p/ SP) | Contexto municipal |
| Diretório de municípios (`br_bd_diretorios_brasil.municipio`) | BigQuery / basedosdados | Não | Chave/IDs municipais |
| **SSP-SP ocorrências** (`br_sp_gov_ssp.ocorrencias_registradas`) | BigQuery / basedosdados | **Sim — exclusivo de SP** | Criminalidade municipal |
| `isdp_scraper` base mensal (`base_mensal_v8_2023.csv`) | Projeto externo, fora do repositório | **Sim — scraper da SSP-SP** | Criminalidade municipal |
| Dados criminais SSP 2025 (`SPDadosCriminais`, `DadosProdutividade`) | `validation/data/criminais/` | **Sim — SSP-SP** | Validação |
| Dados de saúde municipal (HIV/TB/hepatite, casos e óbitos) | 🟩 **DATASUS / Ministério da Saúde** (SINAN tuberculose/hepatite; aids.gov.br HIV; mortalidade CID-10), conforme Nota Metodológica — **nacional**. No repo só existe o script; os dados **não foram commitados** | **Não** (DATASUS é nacional) | Panorama de Saúde / validação |

> 🟩 **Verificação (todo o histórico git):** varredura de `git log --all --diff-filter=A` em todas as branches e commits confirma que **nenhum arquivo de dados de saúde** (`validation/data/saude/*`, `sp_municipios.xlsx`) foi commitado — apenas o script `validation/health_data_processing.R`. Não há commits soltos (`git fsck` limpo). A origem (DATASUS) foi identificada pela **Nota Metodológica do Monitor SP** (ver §8), não pelo repositório.

## 5. Outputs gerados

| Arquivo | Tamanho aprox. | Gerado por |
|---------|----------------|-----------|
| `data-raw/Base_Sisdepen.xlsx` | ~1,8 MB | `depen.R` e depois `dados_sem2.R` (final) |
| `data-raw/Perfil_SP.xlsx` | ~552 KB | `depen.R` |
| `data-raw/populacao_municipios_sp.xlsx` | ~36 KB | `dados municípios_variaveis.R` |
| `data-raw/pib_municipios_sp.xlsx` | ~16 KB | `dados municípios_variaveis.R` |
| `data-raw/ideb_municipios_sp.xlsx` | ~13 KB | `dados municípios_variaveis.R` |
| `data-raw/dados_ssp_2023.xlsx` | ~29 KB | `dados municípios_variaveis.R` |
| `validation/data/criminais/resultado_final_criminais_sp.xlsx` | — | `criminal_data_proccessing.R` |
| `validation/data/saude/resultado_final_saude_sp.xlsx` | — | `health_data_processing.R` |

Insumos de referência presentes em `data-raw` (não gerados pelo código): `mapa_variaveis_SISDEPEN.xlsx` (~427 KB), `Variaveis_Secoes1_2.xlsx` (~415 KB), `Variaveis_Secoes1a4.xlsx` (~7,5 MB), `Dicionário de Variáveis - Base Sisdepen Painel.xlsx` (~32 KB), `pib-municipios-2021_site.xlsx` (~93 KB). Arquivos brutos dos ciclos de 2º semestre (branch `sem_02`) variam de ~2,8 MB a ~7,1 MB cada.

## 6. Dependências

**Ambiente:** R + RStudio (projeto `.Rproj`). Nenhum `renv.lock`, `DESCRIPTION` ou `requirements` — não há gestão de versões de pacotes.

**Pacotes R utilizados:**

- `tidyverse` (núcleo: `dplyr`, `readxl`, `stringr`, `tidyr`, `purrr`, `tibble`) — todos os scripts de pipeline.
- `writexl` — escrita de `.xlsx`.
- `readxl` — leitura de `.xlsx`.
- `basedosdados` — acesso a BigQuery (apenas `dados municípios_variaveis.R`).

**Dependências externas / de infraestrutura:**

- **Conta Google Cloud com billing** `prisional-system-monitor` para `basedosdados`/BigQuery.
- Projeto externo **`isdp_scraper`** (esperado em `../isdp_scraper/`), fora deste repositório.
- **Google Sheets + Looker Studio** para publicação (passo manual de upload da planilha final).

## 7. Pontos de atenção específicos de SP (para a adaptação ao RS)

São observações de fato, relevantes ao diagnóstico de viabilidade:

- Filtro `UF == "SP"` está **hardcoded** em `depen.R` e `dados_sem2.R` — trocável por `"RS"`, mas precisa varredura completa.
- A fonte primária (SISDEPEN/SENAPPEN) é **nacional**, então as bases por ciclo cobrem o RS sem mudança de fonte; muda apenas o filtro de UF.
- Fontes **exclusivas de SP**: tabela `br_sp_gov_ssp.ocorrencias_registradas` (basedosdados) e o `isdp_scraper` (scraper da SSP-SP). Para o RS seria necessário equivalente da **SSP-RS / Secretaria de Segurança do RS**.
- Arquivos de validação (criminais e saúde) são de municípios de SP — exigiriam equivalentes do RS.
- Reprodutibilidade frágil: código e dados em branches separadas, acoplamento por objeto em memória entre `depen.R` e `dados_sem2.R`, ausência de lockfile de pacotes e billing GCP próprio.

## 8. Nota Metodológica do Monitor SP (fonte externa autoritativa)

🟩 Documento oficial do NEV-USP (criado em 10/02/2026), preservado em `docs/referencias/Nota_Metodologica_Monitor_SP.pdf`. Descreve **o que o monitor publica** — informação que o repositório de código sozinho não revela. Pontos que qualificam este inventário:

- **Unidade de observação:** 645 municípios paulistas, agregáveis em 11 macrorregiões administrativas. Atualização **anual por compilação manual**.
- **Dados de Contexto:** Panorama Populacional (censos IBGE), Panorama Econômico (PIB IBGE desde 2010), **Panorama de Saúde (DATASUS/Ministério da Saúde** — tuberculose, hepatite, HIV e mortalidade CID-10, desde 2018), Panorama Educacional (INEP).
- 🟩 **Educação — código × monitor publicado (esclarecido):** o script `dados municípios_variaveis.R` busca **IDEB** (`br_inep_ideb.municipio`), mas, conforme M. Martins (equipe SP, 10/06/2026), **esse dado não é usado** no monitor. O indicador publicado é a **taxa de distorção idade-série** (INEP), extraída da planilha do INEP **manualmente no Excel** — não há script para ela (automação em desenvolvimento). Ou seja, há código vestigial (IDEB) e uma etapa manual fora do repositório (distorção idade-série).
- **Dinâmica Criminal:** fonte SSP-SP (`/estatistica/consultas`), ocorrências desde 2001, **volume anual = soma dos semestres**. Rubricas: homicídio doloso, estupro, roubo, furto, porte ilegal de arma e prisões efetuadas. Definições oficiais (cruciais para o de-para):
  1. Homicídio doloso **não** inclui vítimas de dolosos de trânsito;
  2. Roubo e furto consideram **apenas a categoria "outros"** — excluem carga, veículo, banco e demais variações;
  3. Estupro = **soma de todos os tipos, incluindo vulnerável** (sem recorte de sexo);
  4. **Armas apreendidas e prisões efetuadas vêm da seção "Dados de Produtividade"** da SSP-SP.
- **Taxas relativas:** por 100 mil habitantes, plotadas em mapa (Looker Studio / Dados Cartográficos).
- **Dados Prisionais (SISDEPEN, desde 2017):** confirma o uso de **1º semestre** para Transparência/Estabelecimentos/Morbidade e **2º semestre** para Mortalidade — exatamente a divisão entre `depen.R` e `dados_sem2.R`. Seções: Capacidade/Lotação, Estrutura, Celas, Pessoal, Saúde (consultórios e consultas médicas/odontológicas), Educação, Trabalho, População Prisional, Morbidade/Mortalidade, Controle e Fiscalização. 183 estabelecimentos em SP.

---
*Fonte: inspeção (somente leitura) do repositório `MonitorPrisional2024` em 2026-06-09 (branch de código `R`@`efe1a1a`) e da Nota Metodológica do Monitor SP. Nenhum arquivo do repositório SP foi alterado.*
